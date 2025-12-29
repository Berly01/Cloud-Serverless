#define USE_ARDUINO_INTERRUPTS true

#include <WiFiNINA.h>
#include <PulseSensorPlayground.h>

// -------- WIFI --------
const char* WIFI_SSID = "wifi-CsComputacion";
const char* WIFI_PASS = "EPCC2022$";

// -------- PC SERVER --------
const char* SERVER_IP = "10.7.134.141"; // IP de tu PC
const int   SERVER_PORT = 5000;

// -------- SENSOR --------
#define PULSE_PIN A0
#define LED_PIN LED_BUILTIN

PulseSensorPlayground pulseSensor;
WiFiClient client;

unsigned long lastSend = 0;
const unsigned long SEND_INTERVAL = 1000;
int lastBPM = 0;

void connectWiFi() {
  Serial.print("Conectando WiFi...");
  while (WiFi.begin(WIFI_SSID, WIFI_PASS) != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nWiFi OK");
}

void connectServer() {
  while (!client.connected()) {
    Serial.print("Conectando a PC...");
    if (client.connect(SERVER_IP, SERVER_PORT)) {
      Serial.println("OK");
    } else {
      Serial.println("ERROR");
      delay(2000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  pulseSensor.analogInput(PULSE_PIN);
  pulseSensor.blinkOnPulse(LED_PIN);
  pulseSensor.setThreshold(550);

  if (!pulseSensor.begin()) {
    Serial.println("ERROR PulseSensor");
    while (1);
  }

  connectWiFi();
  connectServer();
}

void loop() {
  if (!client.connected()) {
    connectServer();
  }

  if (pulseSensor.sawStartOfBeat()) {
    int bpm = pulseSensor.getBeatsPerMinute();
    if (bpm >= 40 && bpm <= 180) {
      lastBPM = bpm;
    }
  }

  if (millis() - lastSend > SEND_INTERVAL && lastBPM > 0) {
    unsigned long ts = millis();
    client.print(ts);
    client.print(",");
    client.println(lastBPM);
    lastSend = millis();
  }
}
