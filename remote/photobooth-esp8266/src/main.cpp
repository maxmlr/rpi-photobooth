/*
 ESP8266 MQTT photobooth remote for ESP-01(S) / ESP-12 (Wemos D1 mini)
 @author maximilian miller (miller.deutschland@gmail.com)
 @version 0.12

 Dependencies:
  - Platform:  espressif8266
  - Framework: arduino
  - Libraries:
    + ESP8266WiFi
    + PubSubClient
    + JLed
*/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <jled.h>

// choose type: [REMOTE,RELAY]
#define REMOTE

// choose trigger action: [PHOTO,COLLAGE]
#define PHOTO

const char* SSID = "photobooth";
const char* PASSWORD = "";
const char* MQTT_SERVER = "photobooth";

unsigned int BUTTON_PIN;
unsigned int LED_PIN;

#ifdef ARDUINO_ESP8266_ESP01
#define BUTTON_PIN 0
#define LED_PIN 2
#define LED_ONBOARD 2
#elif defined(ARDUINO_ESP8266_WEMOS_D1MINI)
#define BUTTON_PIN D6
#define LED_PIN D7
#define LED_ONBOARD LED_BUILTIN
#endif


#ifdef PHOTO
String trigger = "p";
#elif defined(COLLAGE)
String trigger = "c";
#endif

WiFiClient espClient;
PubSubClient mqtt(espClient);
String hostname = "photobooth-r" + String(ESP.getChipId());
JLed led = JLed(LED_PIN);
JLed led_onboard = JLed(LED_ONBOARD).LowActive();

volatile bool ButtonPressedFlag = false;
long ButtonPressedLast = 0;
int ButtonPressedLock = 1000;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(SSID);
  WiFi.hostname(hostname);
  WiFi.begin(SSID, PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  randomSeed(micros());
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  Serial.println(hostname);
  led_onboard.Blink(500, 500).Repeat(2);
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("recieved [");
  Serial.print(topic);
  Serial.print("] : ");
  String value = "";
  for (unsigned int i = 0; i < length; i++) {
    value += (char)payload[i];
  }
  Serial.println(value);

  if (!strcmp(topic, "photobooth/remote/callback") || !strcmp(topic, ("photobooth/remote/" + hostname).c_str())) {
    if (value.startsWith("a")) {
        String action = value.substring(1);
        if (action == "1") {
          #ifdef REMOTE
          led.On();
          #elif defined(RELAY)
          digitalWrite(BUTTON_PIN, LOW);
          #endif
        } else if (action == "0") {
          #ifdef REMOTE
          led.Off();
          #elif defined(RELAY)
          digitalWrite(BUTTON_PIN, HIGH);
          #endif
        }
    } else if (value.startsWith("s")) {
      String action = value.substring(1);
      led_onboard.Blink(100, 100).Repeat(action.toInt());
    }
  } else if (!strcmp(topic, "photobooth/link")) {
    if (value == "discover") {
      mqtt.publish("photobooth/link/available", (hostname + "@" + WiFi.localIP().toString()).c_str());
    } 
  }
}

#ifdef REMOTE
ICACHE_RAM_ATTR void ButtonPressed() {
  int button = digitalRead(BUTTON_PIN);
  if(button == LOW)
  {
    ButtonPressedFlag = true;
  }
  return;
}

void button_update() {
  if ( ButtonPressedFlag ) {
    long now = millis();
    if (now - ButtonPressedLast > ButtonPressedLock) {
      ButtonPressedLast = now;
      Serial.println("Butten pressed - sending: trigger to photobooth/remote");
      mqtt.publish("photobooth/remote", ("trigger-" + trigger).c_str());
    }
    ButtonPressedFlag = false;
  }
}
#endif

void setup_gpios() {
  #ifdef REMOTE
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  attachInterrupt(BUTTON_PIN, ButtonPressed, FALLING);
  #elif defined(RELAY)
  digitalWrite(BUTTON_PIN, HIGH);
  pinMode(BUTTON_PIN, OUTPUT);
  #endif
}

void setup_mqtt() {
  mqtt.setServer(MQTT_SERVER, 1883);
  mqtt.setCallback(callback);
}

void mqtt_reconnect() {
  while (!mqtt.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (mqtt.connect(hostname.c_str())) {
      Serial.println("connected");
      mqtt.publish("photobooth/link/register", (hostname +"/" +  WiFi.macAddress()).c_str());
      mqtt.subscribe("photobooth/link");
      mqtt.subscribe("photobooth/remote/callback");
      mqtt.subscribe(("photobooth/remote/" + hostname).c_str());
      led_onboard.Blink(100, 100).Repeat(3);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqtt.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void mqtt_update() {
  if (!mqtt.connected()) {
    mqtt_reconnect();
  }
  mqtt.loop();
}

void led_update() {
  led.Update();
  led_onboard.Update();
}

void setup() {
  led_onboard.On();
  Serial.begin(115200);
  setup_wifi();
  setup_gpios();
  setup_mqtt();
  led_onboard.Off();
}

void loop() {
  mqtt_update();
  led_update();
  #ifdef REMOTE
  button_update();
  #endif
}
