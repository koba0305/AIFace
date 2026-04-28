import processing.sound.*;

AudioIn in;
Amplitude amp;

float smoothLevel = 0.0;
String currentFace = ":)";
int nextFaceAtMs = 0;
int recentHighUntilMs = 0;
boolean rotateFace90 = true;

String[] silentFaces = {
  ":I", ":|",":( ",
};

String[] lowFaces = {
  ":)",";)", ":]", ":}", ":]"
};

String[] midFaces = {
  ":D", ":1", ":o",  ";)",  ";l"
};

String[] highFaces = {
  ":D", ":O",":O"
};

String[] peakFaces = {
":0",":X"
};

String[] specialFaces = {
 ":3"
};

void setup() {
  size(700, 380);

  Sound s = new Sound(this);
  s.inputDevice(13);   // BlackHole 16ch (JavaSound id)
  // s.outputDevice(17); // 必要なら任意

  in = new AudioIn(this, 0); // ch0を読む
  in.start();

  amp = new Amplitude(this);
  amp.input(in);
}


void draw() {
  background(18, 20, 28);

  float raw = amp.analyze();
  smoothLevel = lerp(smoothLevel, raw, 0.2);

  // Keep a short "recently loud" window for special faces.
  if (smoothLevel > 0.09) {
    recentHighUntilMs = millis() + 1000;
  }

  if (millis() >= nextFaceAtMs) {
    currentFace = pickDisplayFace(smoothLevel);
    nextFaceAtMs = millis() + 400;
  }

  float sz = map(constrain(smoothLevel, 0, 0.35), 0, 0.35, 72, 140);
  textSize(sz);

  float r = map(constrain(smoothLevel, 0, 0.35), 0, 0.35, 200, 255);
  float g = map(constrain(smoothLevel, 0, 0.35), 0, 0.35, 220, 110);
  float b = map(constrain(smoothLevel, 0, 0.35), 0, 0.35, 255, 120);
  fill(r, g, b);
  drawFaceText(currentFace);

  drawMeter(raw, smoothLevel);
}

String pickFaceByLevel(float lvl) {
  if (lvl > 0.18) {
    return pick(peakFaces);
  } else if (lvl > 0.10) {
    return pick(highFaces);
  } else if (lvl > 0.045) {
    return pick(midFaces);
  } else if (lvl > 0.018) {
    return pick(lowFaces);
  } else {
    return pick(silentFaces);
  }
}

String pickDisplayFace(float lvl) {
  if (useSpecialFace(lvl)) {
    return pick(specialFaces);
  }
  return pickFaceByLevel(lvl);
}

String pick(String[] faces) {
  int i = int(random(faces.length));
  return faces[i];
}

boolean useSpecialFace(float lvl) {
  if (millis() > recentHighUntilMs) return false;
  if (lvl < 0.06) return false;
  return random(1) < 0.15;
}

void drawFaceText(String face) {
  if (!rotateFace90) {
    text(face, width / 2, height / 2 - 10);
    return;
  }

  pushMatrix();
  translate(width / 2, height / 2 - 10);
  rotate(HALF_PI);
  text(face, 0, 0);
  popMatrix();
}

void drawMeter(float raw, float smoothed) {
  noStroke();
  fill(55);
  rect(40, height - 34, width - 80, 16, 8);

  float rawW = map(constrain(raw, 0, 0.35), 0, 0.35, 0, width - 80);
  float smoothW = map(constrain(smoothed, 0, 0.35), 0, 0.35, 0, width - 80);

  fill(90, 170, 255, 180);
  rect(40, height - 34, rawW, 16, 8);
  fill(120, 255, 160, 210);
  rect(40, height - 34, smoothW, 16, 8);

  fill(200);
  textSize(16);
  text("raw: " + nf(raw, 1, 3) + "   smooth: " + nf(smoothed, 1, 3), width / 2, height - 56);
}
