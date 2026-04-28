import processing.sound.*;

int[] deviceCandidates = {13, 1, 14, 2};
int deviceIdx = 0;
int channel = 0;

Sound sound;
AudioIn in;
Amplitude amp;

float raw = 0;
float smooth = 0;
String status = "";

void setup() {
  size(980, 340);
  textFont(createFont("Menlo", 14));
  printArray(Sound.list());
  openInput(deviceCandidates[deviceIdx], channel);
}

void draw() {
  background(16);
  try {
    raw = amp.analyze();
  } catch (Exception e) {
    raw = 0;
  }
  smooth = lerp(smooth, raw, 0.2);

  float vis = constrain(smooth * 1600.0, 0, 1);
  int barW = int((width - 80) * vis);

  fill(50);
  rect(40, 140, width - 80, 32);
  fill(90, 220, 140);
  rect(40, 140, barW, 32);

  fill(230);
  textSize(18);
  text("BlackHole 16ch Processing Sound test", 40, 42);
  textSize(14);
  text("device id: " + deviceCandidates[deviceIdx] + "   channel: " + channel, 40, 70);
  text("raw: " + nf(raw, 1, 6) + "   smooth: " + nf(smooth, 1, 6), 40, 92);
  text(status, 40, 118);
  text("keys: [ ] = channel 0..15   - = prev device   = = next device   r = reopen", 40, 250);

  if (smooth < 0.0005) {
    fill(255, 190, 130);
    text("No signal detected.", 40, 280);
  } else {
    fill(120, 240, 150);
    text("Signal detected.", 40, 280);
  }
}

void keyPressed() {
  if (key == '[') {
    channel = max(0, channel - 1);
    openInput(deviceCandidates[deviceIdx], channel);
  } else if (key == ']') {
    channel = min(15, channel + 1);
    openInput(deviceCandidates[deviceIdx], channel);
  } else if (key == '-') {
    deviceIdx = (deviceIdx - 1 + deviceCandidates.length) % deviceCandidates.length;
    openInput(deviceCandidates[deviceIdx], channel);
  } else if (key == '=') {
    deviceIdx = (deviceIdx + 1) % deviceCandidates.length;
    openInput(deviceCandidates[deviceIdx], channel);
  } else if (key == 'r' || key == 'R') {
    openInput(deviceCandidates[deviceIdx], channel);
  }
}

void openInput(int deviceId, int ch) {
  try {
    if (in != null) in.stop();
  } catch (Exception e) {
  }

  try {
    sound = new Sound(this);
    sound.inputDevice(deviceId);

    in = new AudioIn(this, ch);
    in.start();
    amp = new Amplitude(this);
    amp.input(in);
    status = "opened: device " + deviceId + " ch " + ch;
    println("[test] " + status);
  } catch (Exception e) {
    status = "open failed: device " + deviceId + " ch " + ch + " / " + e.getMessage();
    println("[test] " + status);
  }
}
