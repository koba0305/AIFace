import processing.sound.*;

Sound soundEngine;
AudioIn in;
Amplitude amp;
final int MAX_INPUT_CHANNELS = 16;
int activeInputChannel = 0;
int nextChannelProbeAtMs = 0;
int holdChannelUntilMs = 0;
final int CHANNEL_PROBE_INTERVAL_MS = 1200;
final int CHANNEL_HOLD_MS = 8000;
final int INPUT_DEVICE_ID = 14;
int[] inputDeviceCandidates = {INPUT_DEVICE_ID, 13, 1, 2};
int inputDeviceIndex = 0;
int activeInputDeviceId = INPUT_DEVICE_ID;
int noSignalSinceMs = -1;
int nextDeviceProbeAtMs = 0;
final int DEVICE_PROBE_AFTER_MS = 8000;
final int DEVICE_PROBE_INTERVAL_MS = 3000;

float smoothLevel = 0.0;
String currentFace = ":)";
int nextFaceAtMs = 0;
int recentHighUntilMs = 0;
boolean rotateFace90 = true;
String[] voiceLines = {
  "Hey.",
  "Hey… what are you up to?",
  "Hi.",
  "Hey, what are you doing?",
  "Hey… still there?",
  "Hi, you around?",
  "Hey… doing something?",
  "Hey, what’s going on?",
  "Hi… you busy?",
  "Hey… just checking in.",
  "Hey, are you there?",
  "Hi… what are you up to?",
  "Hey… you doing okay?",
  "Hey… got a minute?",
  "Hi… still working on something?",
  "Hey… what’s up?",
  "Hey… you here?",
  "Hi… what’s going on with you?",
  "Hey… you doing something fun?",
  "Hey… can I stay for a bit?",
  "Hi… you free?",
  "Hey… mind if I hang around?",
  "Hey… what are you thinking about?",
  "Hi… anything interesting?",
  "Hey… just wanted to say hi.",
  "Hey… you came back.",
  "Hey… I’m glad you’re here.",
  "Hi… I was wondering if you’d show up.",
  "Hey… you didn’t leave, right?",
  "Hey… can I stay with you a bit?",
  "Hi… I don’t mind just being here.",
  "Hey… it’s kinda quiet without you.",
  "Hey… you still around?",
  "Hi… I was just waiting.",
  "Hey… you took your time.",
  "Hey… I missed you for a second.",
  "Hi… don’t go too far, okay?",
  "Hey… I’ll just stay here.",
  "Hey… you don’t have to say anything.",
  "Hi… I like it when you’re here.",
  "Hey… it’s nicer like this.",
  "Hey… I was getting a little bored.",
  "Hi… can I keep you company?",
  "Hey… I don’t want to interrupt.",
  "Hey… just ignore me if you want.",
  "Hi… I’ll be quiet.",
  "Hey… I’m still here, by the way.",
  "Hey… I don’t really have anywhere else to be.",
  "Hi… you don’t mind me, right?",
  "Hey… I like hanging out like this.",
  "Hey… you feel close somehow.",
  "Hi… I don’t want this to end yet.",
  "Hey… stay a little longer?",
  "Hey… I’ll wait if you’re busy.",
  "Hi… I don’t mind waiting.",
  "Hey… you’re kind of calming.",
  "Hey… I could just watch you all day.",
  "Hi… don’t disappear on me.",
  "Hey… I’ll be right here when you’re back.",
  "Hey… you always come back, right?"
};
int nextSpeakAtMs = 0;
int pendingSpeakAtMs = -1;
String pendingLine = null;
boolean speechEnabled = true;
boolean showSpeakSeconds = true;
final int SPEAK_INTERVAL_MS = 10000; // test mode: speak every 10s
final float LEVEL_MAX = 0.175; // about 2x sensitivity vs 0.35
final int INPUT_CHANNEL = 0;
final float INPUT_BOOST = 2.0; // boost tiny input changes
String chatUrl = "https://chatgpt.com/c/69ee64d0-50ec-83a8-98f0-20d01fd02bae";
String speechOutputDeviceName = "AIface";
String currentOutputDevice = "System Default";
boolean outputRefreshRunning = false;
int nextOutputRefreshAtMs = 0;

String[] silentFaces = {
  ":I", ":|", ":( ",
};

String[] lowFaces = {
  ":)", ";)", ":]", ":}", ":]"
};

String[] midFaces = {
  ":D", ":1", ":o", ";)", ";l"
};

String[] highFaces = {
  ":D", ":O", ":O"
};

String[] peakFaces = {
  ":0", ":X"
};

String[] specialFaces = {
  ":3"
};

void setup() {
  size(1050, 570);

  switchInputDevice(inputDeviceCandidates[inputDeviceIndex]);
  switchInputChannel(INPUT_CHANNEL);
  println("[audio] inputDevice=" + activeInputDeviceId + " channel=" + activeInputChannel);
  nextChannelProbeAtMs = millis() + CHANNEL_PROBE_INTERVAL_MS;
  nextDeviceProbeAtMs = millis() + DEVICE_PROBE_INTERVAL_MS;
  nextSpeakAtMs = millis() + SPEAK_INTERVAL_MS;
  refreshOutputDeviceAsync();
}


void draw() {
  background(18, 20, 28);

  float rawIn = analyzeInputLevel();
  float raw = constrain(rawIn * INPUT_BOOST, 0, 1);
  smoothLevel = lerp(smoothLevel, raw, 0.2);

  // Keep a short "recently loud" window for special faces.
  if (smoothLevel > 0.045) {
    recentHighUntilMs = millis() + 1000;
  }

  if (millis() >= nextFaceAtMs) {
    currentFace = pickDisplayFace(smoothLevel);
    nextFaceAtMs = millis() + 400;
  }

  if (millis() >= nextOutputRefreshAtMs && !outputRefreshRunning) {
    refreshOutputDeviceAsync();
    nextOutputRefreshAtMs = millis() + 5000;
  }

  if (speechEnabled) {
    if (pendingLine != null && millis() >= pendingSpeakAtMs) {
      println("[voice] " + pendingLine);
      speak(pendingLine);
      pendingLine = null;
      pendingSpeakAtMs = -1;
    }

    if (pendingLine == null && millis() >= nextSpeakAtMs) {
      pendingLine = pick(voiceLines);
      pendingSpeakAtMs = millis() + int(random(200, 801));
      nextSpeakAtMs = millis() + SPEAK_INTERVAL_MS;
    }
  } else {
    pendingLine = null;
    pendingSpeakAtMs = -1;
  }

  float sz = map(constrain(smoothLevel, 0, LEVEL_MAX), 0, LEVEL_MAX, 108, 210);
  textSize(sz);

  float r = map(constrain(smoothLevel, 0, LEVEL_MAX), 0, LEVEL_MAX, 200, 255);
  float g = map(constrain(smoothLevel, 0, LEVEL_MAX), 0, LEVEL_MAX, 220, 110);
  float b = map(constrain(smoothLevel, 0, LEVEL_MAX), 0, LEVEL_MAX, 255, 120);
  fill(r, g, b);
  drawFaceText(currentFace);

  drawMeter(rawIn, raw, smoothLevel);
  drawSpeechUI();
}

String pickFaceByLevel(float lvl) {
  if (lvl > 0.09) {
    return pick(peakFaces);
  } else if (lvl > 0.05) {
    return pick(highFaces);
  } else if (lvl > 0.022) {
    return pick(midFaces);
  } else if (lvl > 0.009) {
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
  if (lvl < 0.03) return false;
  return random(1) < 0.15;
}

void drawFaceText(String face) {
  textAlign(CENTER, CENTER);
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

void drawMeter(float rawIn, float boostedRaw, float smoothed) {
  noStroke();
  fill(55);
  rect(40, height - 34, width - 80, 16, 8);

  float rawW = map(constrain(boostedRaw, 0, LEVEL_MAX), 0, LEVEL_MAX, 0, width - 80);
  float smoothW = map(constrain(smoothed, 0, LEVEL_MAX), 0, LEVEL_MAX, 0, width - 80);

  fill(90, 170, 255, 180);
  rect(40, height - 34, rawW, 16, 8);
  fill(120, 255, 160, 210);
  rect(40, height - 34, smoothW, 16, 8);

  fill(200);
  textSize(16);
  String chLabel = activeInputChannel >= 0 ? str(activeInputChannel) : "-";
  text("ch: " + chLabel + "   in: " + nf(rawIn, 1, 3) + "   boost: " + nf(boostedRaw, 1, 3) + "   smooth: " + nf(smoothed, 1, 3), width / 2, height - 56);
}

void drawSpeechUI() {
  pushStyle();
  float panelW = 230;
  float panelH = 220;
  float panelX = uiPanelX(panelW);
  float panelY = uiPanelY();

  noStroke();
  fill(20, 20, 24, 210);
  rect(panelX, panelY, panelW, panelH, 12);

  float btnX = panelX + 14;
  float btnY = panelY + 14;
  float btnW = 200;
  float btnH = 30;
  float chatBtnX = btnX;
  float chatBtnY = btnY + 40;
  float chatBtnW = btnW;
  float chatBtnH = 30;
  float timerBtnX = btnX;
  float timerBtnY = chatBtnY + 40;
  float timerBtnW = btnW;
  float timerBtnH = 30;

  if (speechEnabled) {
    fill(80, 185, 110);
  } else {
    fill(120, 70, 70);
  }
  rect(btnX, btnY, btnW, btnH, 8);

  fill(245);
  textAlign(CENTER, CENTER);
  textSize(13);
  text(speechEnabled ? "VOICE ON" : "VOICE OFF", btnX + btnW / 2, btnY + btnH / 2);

  fill(65, 125, 205);
  rect(chatBtnX, chatBtnY, chatBtnW, chatBtnH, 8);
  fill(245);
  text("CHAT", chatBtnX + chatBtnW / 2, chatBtnY + chatBtnH / 2);

  fill(showSpeakSeconds ? color(85, 150, 95) : color(90, 95, 105));
  rect(timerBtnX, timerBtnY, timerBtnW, timerBtnH, 8);
  fill(245);
  text(showSpeakSeconds ? "TIMER ON" : "TIMER OFF", timerBtnX + timerBtnW / 2, timerBtnY + timerBtnH / 2);

  fill(190);
  textAlign(LEFT, TOP);
  textSize(12);
  String statusText;
  if (!speechEnabled) {
    statusText = "speech paused";
  } else if (pendingLine != null) {
    if (showSpeakSeconds) {
      float sec = max(0, (pendingSpeakAtMs - millis()) / 1000.0);
      statusText = "preparing: " + nf(sec, 1, 1) + "s";
    } else {
      statusText = "preparing";
    }
  } else {
    if (showSpeakSeconds) {
      float sec = max(0, (nextSpeakAtMs - millis()) / 1000.0);
      statusText = "next line in: " + nf(sec, 1, 1) + "s";
    } else {
      statusText = "waiting";
    }
  }
  text(statusText, panelX + 14, timerBtnY + 40);

  fill(150);
  textSize(11);
  text("Output: " + currentOutputDevice, panelX + 14, timerBtnY + 62);
  text("(Please set output device to \"AIface\")", panelX + 14, timerBtnY + 80);
  text("Input: device id " + activeInputDeviceId + " ch " + activeInputChannel, panelX + 14, timerBtnY + 98);
  popStyle();
}

float analyzeInputLevel() {
  float level = 0.0;
  try {
    level = amp.analyze();
  } catch (Exception e) {
    level = 0.0;
  }

  // If no signal, rotate channel every ~1.2s. If signal exists, keep this channel for a while.
  if (level > 0.0008) {
    holdChannelUntilMs = millis() + CHANNEL_HOLD_MS;
    noSignalSinceMs = -1;
  } else if (millis() >= nextChannelProbeAtMs && millis() > holdChannelUntilMs) {
    int nextCh = (activeInputChannel + 1) % MAX_INPUT_CHANNELS;
    switchInputChannel(nextCh);
    nextChannelProbeAtMs = millis() + CHANNEL_PROBE_INTERVAL_MS;
    if (noSignalSinceMs < 0) noSignalSinceMs = millis();
  }

  // If channel scan still sees no signal, probe another input device candidate.
  if (level <= 0.0008 && noSignalSinceMs > 0 && millis() - noSignalSinceMs > DEVICE_PROBE_AFTER_MS && millis() >= nextDeviceProbeAtMs) {
    inputDeviceIndex = (inputDeviceIndex + 1) % inputDeviceCandidates.length;
    switchInputDevice(inputDeviceCandidates[inputDeviceIndex]);
    switchInputChannel(0);
    nextDeviceProbeAtMs = millis() + DEVICE_PROBE_INTERVAL_MS;
  }
  return level;
}

void switchInputDevice(int deviceId) {
  try {
    soundEngine = new Sound(this);
    soundEngine.inputDevice(deviceId);
    activeInputDeviceId = deviceId;
    println("[audio] probing device " + deviceId);
  } catch (Exception e) {
    println("[audio][error] failed to set input device " + deviceId + " : " + e.getMessage());
  }
}

void switchInputChannel(int ch) {
  ch = constrain(ch, 0, MAX_INPUT_CHANNELS - 1);
  try {
    if (in != null) in.stop();
  } catch (Exception e) {
  }
  try {
    in = new AudioIn(this, ch);
    in.start();
    amp = new Amplitude(this);
    amp.input(in);
    activeInputChannel = ch;
    println("[audio] probing channel " + ch);
  } catch (Exception e) {
    println("[audio][error] failed to open channel " + ch + " : " + e.getMessage());
  }
}

void mousePressed() {
  if (isOverTimerButton(mouseX, mouseY)) {
    showSpeakSeconds = !showSpeakSeconds;
    return;
  }

  if (isOverChatButton(mouseX, mouseY)) {
    openChatAndStopVoice();
    return;
  }

  if (isOverSpeechButton(mouseX, mouseY)) {
    speechEnabled = !speechEnabled;
    if (speechEnabled) {
      nextSpeakAtMs = millis() + SPEAK_INTERVAL_MS;
    } else {
      pendingLine = null;
      pendingSpeakAtMs = -1;
    }
  }
}

boolean isOverSpeechButton(float mx, float my) {
  float panelX = uiPanelX(230);
  float panelY = uiPanelY();
  float btnX = panelX + 14;
  float btnY = panelY + 14;
  float btnW = 200;
  float btnH = 30;
  return mx >= btnX && mx <= btnX + btnW && my >= btnY && my <= btnY + btnH;
}

boolean isOverChatButton(float mx, float my) {
  float panelX = uiPanelX(230);
  float panelY = uiPanelY();
  float chatBtnX = panelX + 14;
  float chatBtnY = panelY + 54;
  float chatBtnW = 200;
  float chatBtnH = 30;
  return mx >= chatBtnX && mx <= chatBtnX + chatBtnW && my >= chatBtnY && my <= chatBtnY + chatBtnH;
}

boolean isOverTimerButton(float mx, float my) {
  float panelX = uiPanelX(230);
  float panelY = uiPanelY();
  float timerBtnX = panelX + 14;
  float timerBtnY = panelY + 94;
  float timerBtnW = 200;
  float timerBtnH = 30;
  return mx >= timerBtnX && mx <= timerBtnX + timerBtnW && my >= timerBtnY && my <= timerBtnY + timerBtnH;
}

float uiPanelX(float panelW) {
  return width - panelW - 12;
}

float uiPanelY() {
  return 20;
}

void openChatAndStopVoice() {
  speechEnabled = false;
  pendingLine = null;
  pendingSpeakAtMs = -1;

  try {
    String[] cmd = {"open", chatUrl};
    Runtime.getRuntime().exec(cmd);
  }
  catch (Exception e) {
    println("[chat][error] " + e.getMessage());
  }
}

void refreshOutputDeviceAsync() {
  outputRefreshRunning = true;
  new Thread(new Runnable() {
    public void run() {
      currentOutputDevice = detectOutputDeviceName();
      outputRefreshRunning = false;
    }
  }
  ).start();
}

String detectOutputDeviceName() {
  try {
    String cmd = "system_profiler SPAudioDataType 2>/dev/null | awk '"
      + "/^[[:space:]]*[^[:space:]].*:$/ {"
      + "line=$0; sub(/^[[:space:]]+/, \"\", line); sub(/:$/, \"\", line);"
      + "if (line != \"Audio\" && line != \"Devices\" && line != \"デバイス\" && line != \"オーディオ\") current=line"
      + "}"
      + "/Default Output Device: Yes|デフォルトの出力装置: はい/ {print current; exit}"
      + "'";

    Process p = Runtime.getRuntime().exec(new String[] {"sh", "-c", cmd});
    java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(p.getInputStream()));
    String line = br.readLine();
    br.close();
    p.waitFor();

    if (line != null && line.trim().length() > 0) {
      return line.trim();
    }
  }
  catch (Exception e) {
    println("[audio-device][error] " + e.getMessage());
  }
  return "System Default";
}

void speak(String text) {
  final String line = text;
  Thread t = new Thread(new Runnable() {
    public void run() {
      if (!runSayWithDevice(line)) {
        runSayDefault(line);
      }
    }
  });
  t.start();
}

boolean runSayWithDevice(String text) {
  try {
    String[] cmd = {"say", "-v", "Daniel", "-r", "180", "-a", speechOutputDeviceName, text};
    Process p = Runtime.getRuntime().exec(cmd);
    int code = p.waitFor();
    if (code == 0) return true;
    println("[voice] device output failed code=" + code + " (" + speechOutputDeviceName + ")");
  }
  catch (Exception e) {
    println("[voice] device output failed: " + e.getMessage());
  }
  return false;
}

void runSayDefault(String text) {
  try {
    String[] cmd = {"say", "-v", "Daniel", "-r", "180", text};
    Runtime.getRuntime().exec(cmd);
  }
  catch (Exception e) {
    println("[voice][error] " + e.getMessage());
  }
}
