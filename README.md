# rpi-photobooth

## Documentation

### Compatibility
- Raspberry Pi Zero (v1.3)
- Raspberry Pi Zero W (v1.1)
- Raspberry Pi 2B (v1.1)
- Raspberry Pi 4B (v1.2)

### Installation

1. Download latest DietPi and extract image (e.g. using https://www.keka.io/en/) 

```
wget https://dietpi.com/downloads/images/DietPi_RPi-ARMv6-Buster.7z
open -a Keka DietPi_RPi-ARMv6-Buster.7z
```

2. Write image to MicroSD card

- Note: Unmount any volumes associated with the MicroSD card first, e.g. `diskutil unmountDisk /Volumes/boot`.
- Important: Replace *rdisk2* which the appropriate disk (use: `diskutil list` to see all disks)
```
sudo dd if=/<PATH_TO_FOLDER>/DietPi_RPi-ARMv6-Buster/DietPi_RPi-ARMv6-Buster.img of=/dev/rdisk2 bs=1m
```

3. Open `boot/dietpi-wifi.txt` and add your local WiFi SSID and Password. Further, a variety of settings regarding the basic setup of the operating system can be adjusted in `boot/dietpi.txt`.

4. Settings regarding the photobooth app can be changed in `boot/photobooth.conf`

5. Copy all files from the boot folder of this repository to the root of the mounted MicroSD card volume. Replace <YourMicroSD> with the respective mountpoint of your MicroSD card.

```
copy -rf boot/* /Volumes/<YourMicroSD>
```

6. Insert MicroSD card in Raspberry and boot up. The automated installation might take up to 60 minues.
