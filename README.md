# rpi-photobooth

## Installation on Raspberry Zero W (v1.1)

1. Download latest DietPi and extract image (e.g. using https://www.keka.io/en/) 

```
wget https://dietpi.com/downloads/images/DietPi_RPi-ARMv6-Buster.7z
open -a Keka DietPi_RPi-ARMv6-Buster.7z
```

2. Write image to MicroSD card

- Note: Unmount any volumes associated with the MicroSD card first, e.g. `diskutil unmount /Volumes/boot`.
- Important: Replace *rdisk2* which the appropriate disk (use: `diskutil list` to see all disks)
```
sudo dd if=/<PATH_TO_FOLDER>/DietPi_RPi-ARMv6-Buster/DietPi_RPi-ARMv6-Buster.img of=/dev/rdisk2 bs=1m
```

3. Copy all files from the boot folder of this repository to the root of the mounted MicroSD card volume

```
copy boot/* /Volumes/boot
```

4. Insert MicroSD card in Raspberry and boot up. The automated installation might take up to 60 minues.
