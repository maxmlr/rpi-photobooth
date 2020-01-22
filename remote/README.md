# rpi-photobooth - remote control

## Installation on Wemos D1 mini (v3.1.0) [ESP8266]

Uses MQTT notifications
Uses gpio5,6 based push buttons
@author maximilian miller (miller.deutschland@gmail.com)
@version 0.11

### Requires:
    - ESP8266 board/library
    - ESP8266WiFi
    - PubSubClient
 
- It connects to an existing WiFi network and to a specified MQTT server, then:
    - publishes "connected" to the topic "photobooth/remote"
    - subscribes to the topic "photobooth/remote_callback"
    (it assumes the received payloads are strings, not binary)

- It will reconnect to the server if the connection is lost using a blocking
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
    
### Notes:
- LED: LOW is the voltage level but actually the LED is on; this is because it is active low on the ESP-01
- ON:  digitalWrite(BUILTIN_LED, LOW); 
- OFF: digitalWrite(BUILTIN_LED, HIGH);
