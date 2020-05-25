# rpi-photobooth

## Documentation

### Compatibility
Compatible boards:
- Raspberry Pi Zero (v1.3) [+ EW-7811Un USB WiFi Adapter]
- Raspberry Pi Zero W (v1.1)
- Raspberry Pi 2B (v1.1)
- Raspberry Pi 4B (v1.2)

Compatible wifi dongles:
- [Edimax EW-7811Un](https://www.edimax.com/edimax/merchandise/merchandise_detail/data/edimax/in/wireless_adapters_n150/ew-7811un)
- [Edimax EW-7822UTC](https://www.edimax.com/edimax/merchandise/merchandise_detail/data/edimax/global/wireless_adapters_ac1200_dual-band/ew-7822utc)

Compatible ESP-8266(EX) boards:
- ESP-01(S)
- Wemos D1 mini (v3.1.0)

### Installation

Download latest DietPi and extract image (e.g. using https://www.keka.io/en/) 

```
wget https://dietpi.com/downloads/images/DietPi_RPi-ARMv6-Buster.7z
open -a Keka DietPi_RPi-ARMv6-Buster.7z
```

#### Create bootable (auto)

Use the provided `create_bootable.sh` script:
```
Usage: create_bootable.sh [-g|--git <arg>] [-c|--config <arg>] [-d|--dietpi <arg>] [-w|--wifi <arg>] [-k|--key <arg>] [-p|--photobooth <arg>] [-h|--help] <image>
        <image>: path to dietpi image file
        -g, --git: "server", "client" or path to local git repository (default: 'server')
        -c, --config: path to dietpi config file (no default)
        -d, --dietpi: path to dietp.txt file (no default)
        -w, --wifi: path to dietpi-wifi.txt file (no default)
        -k, --key: path to public key file (no default)
        -p, --photobooth: path to photobooth config file (no default)
        -h, --help: Prints help
```
All optional arguments default to repository config files if not specified.
`--key` defaults to `$HOME/.ssh/id_rsa.pub`

#### Create bootable (manual)

1. Write image to MicroSD card

- Note: Unmount any volumes associated with the MicroSD card first, e.g. `diskutil unmountDisk /Volumes/boot`.
- Important: Replace *rdisk2* which the appropriate disk (use: `diskutil list` to see all disks)
```
sudo dd if=/<PATH_TO_FOLDER>/DietPi_RPi-ARMv6-Buster/DietPi_RPi-ARMv6-Buster.img of=/dev/rdisk2 bs=1m
```

2. Edit config files in rpi-photobooth repository
- **WiFi** (`boot/dietpi-wifi.txt`)
  -- Add your local WiFi SSID and Password
- **OS** (`boot/dietpi.txt` and `boot/config.txt`)
  -- Adjust basic setup of the operating system
- **Photobooth** (`boot/photobooth.conf`)
  -- Photobooth app settings

3. Copy all files from the boot folder of this repository to the root of the mounted MicroSD card volume. Replace <YourMicroSD> with the respective mountpoint of your MicroSD card.

```
copy -rf boot/* /Volumes/<YourMicroSD>
```

Insert MicroSD card in Raspberry and boot up. The automated installation might take up to 60 minues.

Attach Hardware Camera Button and LED Panel as described in https://github.com/maxmlr/rpi-photobooth/tree/master/docs/img
