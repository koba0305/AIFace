#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const sketchPath = path.join(root, "forvoice", "sketchvoice.pde");
const rawDir = path.join(root, "forvoice", "data", "robot_voice_raw");
const outDir = path.join(root, "forvoice", "data", "robot_voice");

const sketch = fs.readFileSync(sketchPath, "utf8");
const match = sketch.match(/String\[\]\s+voiceLines\s*=\s*\{([\s\S]*?)\};/);

if (!match) {
  console.error("Could not find voiceLines in sketchvoice.pde");
  process.exit(1);
}

const lines = [...match[1].matchAll(/"([^"]*)"/g)].map((m) => m[1]);

fs.mkdirSync(rawDir, { recursive: true });
fs.mkdirSync(outDir, { recursive: true });

const filter = [
  "highpass=f=120",
  "lowpass=f=6500",
  "acrusher=bits=9:mix=0.25",
  "tremolo=f=55:d=0.35",
  "aecho=0.6:0.3:18:0.25",
].join(",");

for (let i = 0; i < lines.length; i++) {
  const id = String(i).padStart(3, "0");
  const rawPath = path.join(rawDir, `voice_${id}.aiff`);
  const outPath = path.join(outDir, `voice_${id}.m4a`);
  const spokenText = `[[volm 0.70]] ${lines[i]}`;

  console.log(`[${id}] ${lines[i]}`);

  let result = spawnSync("say", ["-v", "Daniel", "-r", "180", "-o", rawPath, spokenText], {
    stdio: "inherit",
  });
  if (result.status !== 0) process.exit(result.status || 1);

  result = spawnSync("ffmpeg", [
    "-y",
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    rawPath,
    "-af",
    filter,
    "-c:a",
    "aac",
    "-b:a",
    "96k",
    outPath,
  ], {
    stdio: "inherit",
  });
  if (result.status !== 0) process.exit(result.status || 1);
}

console.log(`Generated ${lines.length} robot voice files in ${outDir}`);
