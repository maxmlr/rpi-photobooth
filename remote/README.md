# rpi-photobooth - remote control

- Uses MQTT notifications and gpio based push buttons

- It connects to an existing WiFi network and to a specified MQTT server, then:
    - subscribes / publishes to "photobooth/link/[register,available]"
    - publishes to "photobooth/remote
    - subscribes to "photobooth/remote/callback"
    (it assumes the received payloads are strings, not binary)

- It will reconnect to the server if the connection is lost using a blocking
reconnect function. See the 'mqtt_reconnect_nonblocking' example for how to
achieve the same result without blocking the main loop.

## General instructions to flash the ESP8266

Flashing a ESP8266 board (using Arduino 1.8.10+)

### Requirements:
    - ESP8266 board/library
    - ESP8266WiFi
    - PubSubClient
 
### Install Arduino
To isntall using Arduino 1.8.10:
- Download and install Arduino from https://www.arduino.cc/en/Main/Software
- Add the following 3rd party board manager under "File -> Preferences -> Additional Boards Manager URLs":
    http://arduino.esp8266.com/stable/package_esp8266com_index.json
- Open the "Tools -> Board -> Board Manager" and click install for the ESP8266"
- Select your ESP8266 in "Tools -> Board"
- Open "Tools → Port:xxx" and in the dropdown, select the option with "usb(serial)" in its name

### Install Libraries
To install the PubSubClient library:
- Open "Tools → Manage Libraries" and search for PubSubClient and install the "PubSubClient" library

### Flash Board
To connect to the board and flash via USB:
- Downloade and install drivers from https://wiki.wemos.cc/downloads
- Open "Tools → Board:xxx" and select the appropriate board
- Open "Tools → Upload Speed" and select 115200

### Debugging
To read via the Serial Monitor:
    - "Open Tools → Serial Monitor" and set baudrate to 115200
    
### Notes
- LED: LOW is the voltage level but actually the LED is on; this is because it is active low on the ESP-01
- ON:  digitalWrite(BUILTIN_LED, LOW); 
- OFF: digitalWrite(BUILTIN_LED, HIGH);

## Specific instruction per board

### Wemos D1 mini (v3.1.0)
Wemos D1 mini (v3.1.0) [ESP8266]
- Download and install drivers from https://wiki.wemos.cc/downloads
- In Arduino open "Tools → Board:xxx" and select **WeMos D1 R2 & mini**

Arduino IDE settings:
 - Board: LOLIN(WEMOS) D1 R2 & mini
 - Upload Speed: 115200
 - CPU Frequency: 80Mhz
 - Flash Size: 4MB (FS:2MB OTA:~1019KB)
 - Port: tty.usbserial-1410

GPIOs:
 - 6: push button
 - 7: led

 ### ESP-01(S)
 - Downloade and install drivers from https://github.com/adrianmihalko/ch340g-ch34g-ch34x-mac-os-x-driver
 - In Arduino open "Tools → Board:xxx" and select **Generic ESP8266 Module** 
 
 GPIOs:
 - 0: push button
 - 2: led
