#!/usr/bin/env bash

set -xe

zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega8535 main.zig

avr-ld -o main.elf main.o -T avr4.x

avr-objcopy -O ihex -j .text -j .data main.elf main.hex
