#!/bin/bash

targetBaseBackground="../../manager/files/"
targetBaseFrame="../manager/files/"
photoboothConfig="../../config/my.config.inc.php"

targetBaseBackgroundEscaped="$(echo $targetBaseBackground | sed 's/\//\\\//g')"
targetBaseFrameEscaped="$(echo $targetBaseFrame | sed 's/\//\\\//g')"

if [ "$3" = "background" ]; then
    rm -f ../files/selected_background_*
    sed -i -e 's/'\'${1}\'' => '\''url(.*)'\''/'\'${1}\'' => '\''url('${targetBaseBackgroundEscaped}${2}')'\''/g' ${photoboothConfig}
    convert "/var/www/html/manager/files/${2}" -quality 25 -resize 1920x1080\\> /var/www/html/captive/images/bg
elif [ "$3" = "frame" ]; then
    rm -f ../files/selected_frame_*
    if [[ $(grep -c "${1}" ${photoboothConfig}) -eq 0 ]]
    then
        sed -i '/);/i \ \ '\'${1}\'' => '\'${targetBaseFrameEscaped}${2}\'',' ${photoboothConfig}
    else
        sed -i -e 's/'\'${1}\'' => '\''.*'\''/'\'${1}\'' => '\'${targetBaseFrameEscaped}${2}\''/g' ${photoboothConfig}
    fi
fi
