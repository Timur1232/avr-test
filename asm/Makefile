.PHONY: deploy size

deploy: test.hex size
	avrdude -c usbasp -p t13 -P usb -B 9.6 -U flash:w:test.hex:i

size: test.elf
	avr-size test.elf

test.hex: test.elf
	avr-objcopy -O ihex test.elf test.hex

test.elf: test.S
	avr-gcc -mmcu=attiny13a -Os -g -o test.elf test.S

build:
	mkdir build
