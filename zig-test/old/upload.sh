#!/usr/bin/env bash

if [ -e "$1" ]; then
    avrdude -c usbasp -p m8535 -P usb -B 8 -U flash:w:$1:i
else
    echo "No hex files"
fi
