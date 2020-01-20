/*
 Basic ESP8266 MQTT example

 This sketch demonstrates the capabilities of the pubsub library in combination
 with the ESP8266 board/library.

 It connects to an MQTT server then:
  - publishes "hello world" to the topic "outTopic" every two seconds
  - subscribes to the topic "inTopic", printing out any messages
    it receives. NB - it assumes the received payloads are strings not binary
  - If the first character of the topic "inTopic" is an 1, switch ON the ESP Led,
    else switch it off

 It will reconnect to the server if the connection is lost using a blocking
 reconnect function. See the 'mqtt_reconnect_nonblocking' example for how to
 achieve the same result without blocking the main loop.

 To install the ESP8266 board, (using Arduino 1.6.4+):
  - Add the following 3rd party board manager under "File -> Preferences -> Additional Boards Manager URLs":
       http://arduino.esp8266.com/stable/package_esp8266com_index.json
  - Open the "Tools -> Board -> Board Manager" and click install for the ESP8266"
  - Select your ESP8266 in "Tools -> Board"

*/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>

// Update these with values suitable for your network.

const char* ssid = "photobooth";
const char* password = "";
const char* mqtt_server = "photobooth";

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
  Serial.println(ssid);

  WiFi.begin(ssid, password);

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

  // Switch on the LED if an 1 was received as first character
  if ((char)payload[0] == '1') {
    digitalWrite(BUILTIN_LED, LOW);   // Turn the LED on (Note that LOW is the voltage level
    // but actually the LED is on; this is because
    // it is active low on the ESP-01)
  } else {
    digitalWrite(BUILTIN_LED, HIGH);  // Turn the LED off by making the voltage HIGH
  }

}

ICACHE_RAM_ATTR void D5ButtonPressed() {
//  Serial.println("D5ButtonPressed");
  int button = digitalRead(D5_BUTTON_PIN);
  if(button == HIGH)
  {
    D5ButtonPressedFlag = true;
  }
  return;
}

ICACHE_RAM_ATTR void D6ButtonPressed() {
//  Serial.println("D6ButtonPressed");
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
  // It is important to use interupts when making network calls in your sketch
  // if you just checked the status of te button in the loop you might
  // miss the button press.
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
      // Once connected, publish an announcement...
      client.publish("photobooth/remote", "connected");
      // ... and resubscribe
      client.subscribe("inTopic");
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
  pinMode(BUILTIN_LED, OUTPUT);     // Initialize the BUILTIN_LED pin as an output
  digitalWrite(BUILTIN_LED, LOW);
  Serial.begin(115200);
  setup_wifi();
  setup_buttons();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
  led_blink(2,100);
  digitalWrite(BUILTIN_LED, LOW);
}

void loop() {

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

//  long now = millis();
//  if (now - lastMsg > 2000) {
//    lastMsg = now;
//    ++value;
//    snprintf (msg, 50, "hello world #%ld", value);
//    Serial.print("Publish message: ");
//    Serial.println(msg);
//    client.publish("outTopic", msg);
//  }

    long now = millis();
    if ( D5ButtonPressedFlag ) {
      if (now - D5lastMsg > 2000) {
        D5lastMsg = now;
        Serial.println("D5 - sending: trigger-2");
        client.publish("photobooth/remote", "trigger-2");
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
