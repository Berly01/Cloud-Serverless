/*
 * Arduino + Sensor BPM + HC-05 Bluetooth
 * Envía datos de frecuencia cardíaca por Bluetooth al PC
 */

#define USE_ARDUINO_INTERRUPTS true
#include <PulseSensorPlayground.h>
#include <SoftwareSerial.h>

// Configuración del sensor BPM
const int PIN_PULSO = A0;
const int BPM_BAJO = 60;
const int BPM_NORMAL_MAX = 100;
const int BPM_ALTO = 120;

// Configuración HC-05
// Conectar: HC-05 TX → Arduino Pin 10
//           HC-05 RX → Arduino Pin 11
//           HC-05 VCC → 5V
//           HC-05 GND → GND
SoftwareSerial bluetooth(10, 11); // RX, TX

PulseSensorPlayground pulseSensor;

// Variables de control
unsigned long lastSendTime = 0;
const unsigned long SEND_INTERVAL = 2000; // Enviar cada 2 segundos
int lastBpm = 0;

void setup() {
  // Inicializar Serial (para debug)
  Serial.begin(9600);
  
  // Inicializar Bluetooth HC-05 (baudrate por defecto 9600)
  bluetooth.begin(9600);
  
  // Configurar sensor de pulso
  pulseSensor.analogInput(PIN_PULSO);
  pulseSensor.blinkOnPulse(LED_BUILTIN);
  pulseSensor.setThreshold(550);
  
  delay(1000);
  
  // Verificar sensor
  if (!pulseSensor.begin()) {
    Serial.println(F("ERROR: Sensor no detectado"));
    bluetooth.println("ERROR:SENSOR");
    while(1) {
      // Parpadear LED rápido para indicar error
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  }
  
  Serial.println(F("================================="));
  Serial.println(F("Monitor BPM - Fog Computing"));
  Serial.println(F("================================="));
  Serial.println(F("Sistema iniciado correctamente"));
  Serial.println(F("Esperando conexión Bluetooth..."));
  
  bluetooth.println("READY");
}

void loop() {
  unsigned long currentTime = millis();
  
  // Detectar latido
  if (pulseSensor.sawStartOfBeat()) {
    int bpm = pulseSensor.getBeatsPerMinute();
    
    // Validar BPM (filtrar lecturas erróneas)
    if (bpm >= 40 && bpm <= 200) {
      lastBpm = bpm;
      
      // Mostrar en Serial Monitor (debug)
      Serial.print("BPM: ");
      Serial.print(bpm);
      Serial.print(" - Estado: ");
      Serial.println(getEstado(bpm));
      
      // Parpadear LED según el estado
      blinkStatus(bpm);
    }
  }
  
  // Enviar datos por Bluetooth cada SEND_INTERVAL
  if (currentTime - lastSendTime >= SEND_INTERVAL && lastBpm > 0) {
    enviarDatosBluetooth(lastBpm);
    lastSendTime = currentTime;
  }
  
  delay(20);
}

// Enviar datos en formato JSON por Bluetooth
void enviarDatosBluetooth(int bpm) {
  // Formato JSON simple para Python
  bluetooth.print("{\"bpm\":");
  bluetooth.print(bpm);
  bluetooth.print(",\"estado\":\"");
  bluetooth.print(getEstado(bpm));
  bluetooth.println("\"}");
  
  // Log en Serial
  Serial.print("📤 Enviado por BT: BPM=");
  Serial.print(bpm);
  Serial.print(", Estado=");
  Serial.println(getEstado(bpm));
}

// Determinar estado según BPM
const char* getEstado(int bpm) {
  if (bpm < BPM_BAJO) return "BAJO";
  if (bpm <= BPM_NORMAL_MAX) return "NORMAL";
  if (bpm <= BPM_ALTO) return "ALTO";
  return "MUY_ALTO";
}

// Parpadear LED según estado (feedback visual)
void blinkStatus(int bpm) {
  int blinkTimes = 1;
  
  if (bpm < BPM_BAJO) {
    blinkTimes = 1; // BAJO: 1 parpadeo lento
  } else if (bpm <= BPM_NORMAL_MAX) {
    blinkTimes = 2; // NORMAL: 2 parpadeos
  } else if (bpm <= BPM_ALTO) {
    blinkTimes = 3; // ALTO: 3 parpadeos
  } else {
    blinkTimes = 4; // MUY_ALTO: 4 parpadeos rápidos
  }
  
  // Los parpadeos ya los hace la librería, esto es opcional
}

/*
 * NOTAS DE CONEXIÓN HC-05:
 * 
 * HC-05 Module    →    Arduino
 * --------------------------------
 * VCC (5V)        →    5V
 * GND             →    GND
 * TXD             →    Pin 10 (RX del SoftwareSerial)
 * RXD             →    Pin 11 (TX del SoftwareSerial)
 * 
 * IMPORTANTE: 
 * - Si el HC-05 no funciona, verifica que el baudrate sea 9600
 * - Para cambiar baudrate del HC-05, usa comandos AT (busca tutorial)
 * - El LED del HC-05 debe parpadear rápido (sin emparejar) o lento (emparejado)
 * 
 * FORMATO DE DATOS ENVIADOS:
 * {"bpm":75,"estado":"NORMAL"}
 * 
 * Cada línea termina con \n para facilitar lectura en Python
 */