/*
 ESP8266 MQTT notifications for ESP-01(S)
 @author maximilian miller (miller.deutschland@gmail.com)
 @version 0.12

 Requires:
  - ESP8266 board/library
  - ESP8266WiFi
  - PubSubClient

 Documentation:
  https://github.com/maxmlr/rpi-photobooth/tree/master/remote

 Notes:
  It is important to use interupts when making network calls in the sketch.
  If just checking the status of the button in the loop the button press
  might be missed.
*/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>

const char* SSID = "photobooth";
const char* PASSWORD = "";
const char* MQTT_SERVER = "photobooth";

unsigned int BUTTON_PIN;
unsigned int LED_PIN;

// ESP-01S
static const uint8_t D3 = 0;
static const uint8_t D4 = 2;
#define BUTTON_PIN D3
#define LED_PIN D4

// Wemos D1
// #define BUTTON_PIN D6
// #define LED_PIN D7

volatile bool ButtonPressedFlag = false;

WiFiClient espClient;
PubSubClient client(espClient);
long lastMsg = 0;
int countdown = 5000;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(SSID);
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
  led_blink(BUILTIN_LED,2,500,true);
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  if ((char)payload[0] == '1') {
    led_blink(BUILTIN_LED,1,100,true);
  } else {
    led_blink(BUILTIN_LED,2,100,true);
  }
}

ICACHE_RAM_ATTR void ButtonPressed() {
  int button = digitalRead(BUTTON_PIN);
  if(button == HIGH)
  {
    ButtonPressedFlag = true;
  }
  return;
}

void setup_gpios() {
  pinMode(BUTTON_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  attachInterrupt(BUTTON_PIN, ButtonPressed, RISING);
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "ESP8266Client-";
    clientId += String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      Serial.println("connected");
      client.publish("photobooth/remote", "connected");
      client.subscribe("photobooth/remote_callback");
      led_blink(BUILTIN_LED,3,100,true);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void led_blink(int led, int count, int rate, bool inverse) {
  for (int i = 0; i < count; i++)
  {
    if (inverse) {
      digitalWrite(led, LOW);
    } else {
      digitalWrite(led, HIGH);
    }
    delay(rate);
    if (inverse) {
      digitalWrite(led, HIGH);
    } else {
      digitalWrite(led, LOW);
    }
    delay(rate);
  }
  return;
}

void setup() {
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, LOW);
  Serial.begin(115200);
  setup_wifi();
  setup_gpios();
  client.setServer(MQTT_SERVER, 1883);
  client.setCallback(callback);
  digitalWrite(BUILTIN_LED, HIGH);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  long now = millis();
  if ( ButtonPressedFlag ) {
    if (now - lastMsg > countdown) {
      lastMsg = now;
      Serial.println("Butten pressed - sending: trigger");
      client.publish("photobooth/remote", "trigger");
      led_blink(BUILTIN_LED,1,50,true);
      led_blink(LED_PIN,(countdown/1000)-1,1000,false);
      led_blink(LED_PIN,5,50,false);
    }
    ButtonPressedFlag = false;
  }
}
