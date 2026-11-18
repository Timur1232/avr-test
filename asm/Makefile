.PHONY: deploy size

deploy: main.hex size
	avrdude -c usbasp -p t13 -P usb -B 9.6 -U flash:w:main.hex:i

size: main.elf
	avr-size main.elf

main.hex: main.elf
	avr-objcopy -O ihex main.elf main.hex

main.elf: main.S
	avr-gcc -mmcu=attiny13a -Os -g -o main.elf main.S

build:
	mkdir build
