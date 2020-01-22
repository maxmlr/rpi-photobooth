/*
 Wemos D1 mini (v3.1.0) [ESP8266] MQTT notifications
 Uses gpio5,6 based push buttons
 @author maximilian miller (miller.deutschland@gmail.com)
 @version 0.11

 Requires:
 - ESP8266 board/library
 - ESP8266WiFi
 - PubSubClient
 
 It connects to an existing WiFi network and to a specified MQTT server, then:
  - publishes "connected" to the topic "photobooth/remote"
  - subscribes to the topic "photobooth/remote_callback"
    (it assumes the received payloads are strings, not binary)

 It will reconnect to the server if the connection is lost using a blocking
 reconnect function. See the 'mqtt_reconnect_nonblocking' example for how to
 achieve the same result without blocking the main loop.

 To install the ESP8266 board, (using Arduino 1.8.10+):
  - Download and install Arduino from https://www.arduino.cc/en/Main/Software
  - Add the following 3rd party board manager under "File -> Preferences -> Additional Boards Manager URLs":
       http://arduino.esp8266.com/stable/package_esp8266com_index.json
  - Open the "Tools -> Board -> Board Manager" and click install for the ESP8266"
  - Select your ESP8266 in "Tools -> Board"
  - Open "Tools → Port:xxx" and in the dropdown, select the option with "usb" in its name

 To install the PubSubClient library:
  - Open "Tools → Manage Libraries" and search for PubSubClient and install the "PubSubClient" library

 To connect to the board and flash via USB:
  - Downloade and install drivers from https://wiki.wemos.cc/downloads
  - Open "Tools → Board:xxx" and select WeMos D1 R2 & mini
  - Open "Tools → Upload Speed" and select 115200

 To read via the Serial Monitor:
   - "Open Tools → Serial Monitor" and set baudrate to 115200
    
 Notes:
  - LED: LOW is the voltage level but actually the LED is on; this is because it is active low on the ESP-01
    ON:  digitalWrite(BUILTIN_LED, LOW); 
    OFF: digitalWrite(BUILTIN_LED, HIGH);
*/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>

const char* SSID = "photobooth";
const char* PASSWORD = "";
const char* MQTT_SERVER = "photobooth";

#define D5_BUTTON_PIN D5
#define D6_BUTTON_PIN D6

volatile bool D5ButtonPressedFlag = false;
volatile bool D6ButtonPressedFlag = false;

WiFiClient espClient;
PubSubClient client(espClient);
long D5lastMsg = 0;
long D6lastMsg = 0;
char msg[50];
int value = 0;

void setup_wifi() {
  delay(10);
  // We start by connecting to a WiFi network
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
    led_blink(1,100);
  } else {
    led_blink(2,100);
  }
}

ICACHE_RAM_ATTR void D5ButtonPressed() {
  int button = digitalRead(D5_BUTTON_PIN);
  if(button == HIGH)
  {
    D5ButtonPressedFlag = true;
  }
  return;
}

ICACHE_RAM_ATTR void D6ButtonPressed() {
  int button = digitalRead(D6_BUTTON_PIN);
  if(button == HIGH)
  {
    D6ButtonPressedFlag = true;
  }
  return;
}

void setup_buttons() {
  // Initialize the buttons
  pinMode(D5_BUTTON_PIN, INPUT);
  pinMode(D6_BUTTON_PIN, INPUT);

  // NOTE:
  // It is important to use interupts when making network calls in thr sketch.
  // If just checking the status of the button in the loop the button press
  // might be missed.
  attachInterrupt(D5_BUTTON_PIN, D5ButtonPressed, RISING);
  attachInterrupt(D6_BUTTON_PIN, D6ButtonPressed, RISING);
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Create a random client ID
    String clientId = "ESP8266Client-";
    clientId += String(random(0xffff), HEX);
    // Attempt to connect
    if (client.connect(clientId.c_str())) {
      Serial.println("connected");
      // Once connected, publish a successful connection message...
      client.publish("photobooth/remote", "connected");
      // ... and resubscribe
      client.subscribe("photobooth/remote_callback");
      led_blink(5,100);
      digitalWrite(BUILTIN_LED, HIGH);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void led_blink(int count, int rate) {
  for (int i = 0; i < count; i++)
  {
    digitalWrite(BUILTIN_LED, LOW);
    delay(rate);
    digitalWrite(BUILTIN_LED, HIGH);
    delay(rate);
  }
  return;
}

void setup() {
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, LOW);
  Serial.begin(115200);
  setup_wifi();
  setup_buttons();
  client.setServer(MQTT_SERVER, 1883);
  client.setCallback(callback);
  led_blink(2,100);
  digitalWrite(BUILTIN_LED, LOW);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  long now = millis();
  if ( D5ButtonPressedFlag ) {
    if (now - D5lastMsg > 2000) {
      D5lastMsg = now;
      int trigger_state = 2;
      snprintf (msg, 50, "trigger-%ld", trigger_state);
      Serial.print("D5 - sending: ");
      Serial.println(msg);
      client.publish("photobooth/remote", msg);
      led_blink(1,50);
    }
    D5ButtonPressedFlag = false;
  }
  
  if ( D6ButtonPressedFlag ) {
    if (now - D6lastMsg > 2000) {
      D6lastMsg = now;
      Serial.println("D6 - sending: trigger");
      client.publish("photobooth/remote", "trigger");
      led_blink(1,50);
    }
    D6ButtonPressedFlag = false;
  } 
}
