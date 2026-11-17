const io = @import("atmega8535/zig-out/avr_io.zig");
const helpers = @import("helpers.zig");

const bit = helpers.bit;

const E  = bit(5);
const RW = bit(6);
const RS = bit(7);

inline fn send_command() void {
    io.PORTA.* |= E;
    helpers.delay_ms(1);
    io.PORTA.* &= ~E;
}

export fn main() noreturn {
    io.DDRC.* = 0xFF;
    io.DDRA.* |= bit(5) | bit(6) | bit(7);

    // Set 8-bit mode, 2-line display, 5x8 font
    io.PORTC.* = bit(5) | bit(4) | bit(3);
    send_command();
    helpers.delay_ms(1000);

    // Set display on, cursor on, cursor not blink
    io.PORTC.* = bit(3) | bit(2) | bit(1);
    send_command();
    helpers.delay_ms(1000);

    io.PORTA.* |= RS;
    io.PORTC.* = 'H';
    send_command();
    helpers.delay_ms(1000);

    while (true) {
        asm volatile ("nop");
    }
}
