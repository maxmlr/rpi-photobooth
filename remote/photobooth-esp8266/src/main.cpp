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

// choose ESP01 or WEMOSD1
#define ESP01
// choose REMOTE or RELAY
#define REMOTE

const char* SSID = "photobooth";
const char* PASSWORD = "";
const char* MQTT_SERVER = "photobooth";

unsigned int BUTTON_PIN;
unsigned int LED_PIN;

#ifdef ESP01
#define BUTTON_PIN 0
#define LED_PIN 2
#elif defined(WEMOSD1)
#define BUTTON_PIN D6
#define LED_PIN D7
#endif

volatile bool ButtonPressedFlag = false;

WiFiClient espClient;
PubSubClient client(espClient);
String hostname = "photobooth-r" + String(ESP.getChipId());
long lastMsg = 0;
int countdown = 5000;

void led_blink(uint8_t led, int count, int rate, bool inverse) {
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
  led_blink(LED_BUILTIN,2,500,true);
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
          digitalWrite(LED_PIN, HIGH);
        } else if (action == "0") {
          digitalWrite(LED_PIN, LOW); 
        }
    } else if (value.startsWith("s")) {
      String action = value.substring(1);
      led_blink(LED_BUILTIN,action.toInt(),100,true);
    }
  } else if (!strcmp(topic, "photobooth/link")) {
    if (value == "discover") {
      client.publish("photobooth/link/available", (hostname + "@" + WiFi.localIP().toString()).c_str());
    } 
  }
}

ICACHE_RAM_ATTR void ButtonPressed() {
  int button = digitalRead(BUTTON_PIN);
  if(button == LOW)
  {
    ButtonPressedFlag = true;
  }
  return;
}

void setup_gpios() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  attachInterrupt(BUTTON_PIN, ButtonPressed, FALLING);
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(hostname.c_str())) {
      Serial.println("connected");
      client.publish("photobooth/link/register", (hostname +"/" +  WiFi.macAddress()).c_str());
      client.subscribe("photobooth/link");
      client.subscribe("photobooth/remote/callback");
      client.subscribe(("photobooth/remote/" + hostname).c_str());
      led_blink(LED_BUILTIN,3,100,true);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  Serial.begin(115200);
  setup_wifi();
  setup_gpios();
  client.setServer(MQTT_SERVER, 1883);
  client.setCallback(callback);
  digitalWrite(LED_BUILTIN, HIGH);
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
      led_blink(LED_BUILTIN,1,50,true);
      led_blink(LED_PIN,(countdown/1000)-1,1000,false);
      led_blink(LED_PIN,5,50,false);
      digitalWrite(LED_BUILTIN, HIGH);
    }
    ButtonPressedFlag = false;
  }
}
