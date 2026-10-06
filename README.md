# AVR things

My personal exploration of AVR MCU ATMega8535L-8PI.

# Dependences

- GNU AVR toolchain (avr-gcc, avr-objcopy)
- avrdude

# C version

## Compiling and uploading

This project uses library nob.h (https://github.com/tsoding/nob.h).

First compile nob file:

```sh
cc -o nob nob.c
```

Then run with command and name of a main program file without extention (if your program is in `foo.c`, then pass just `foo`).
Possible commands:

- compile - just compile and link program
- upload - compile, link and upload to connected usbasp programmer

```sh
# This command will seek for `led.c` file
./nob compile led
```

# Zig version

My attempt on running zig on this MCU. This contains digit-interrupt example almost one to one.

Zig version:

```sh
$ zig version
0.16.0-dev.3013+abd131e33
```

## Compiling and uploading

Go to `zig-test/src/atmega8535` first:

```sh
cd zig-test/src/atmega8535
```

Run zig build to generate avr/io.h bindings:

```sh
zig build
```

Go back to `zig-test` and run zig build:

```sh
cd ..
zig build
```

Run this to upload program to connected usbasp programmer:

```sh
zig build upload
```
