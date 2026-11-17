const seg7 = @import("seven_segment.zig");
const io = @import("atmega8535/zig-out/avr_io.zig");
const helpers = @import("helpers.zig");

const bit = helpers.bit;

const START_BIT = (@as(u8, 1) << io.PD6);
const START_NUMBER = 15;

var number: u8 = START_NUMBER;

fn decrement_number() callconv(.avr_signal) void {
    if (number == 0) {
        number = START_NUMBER;
    } else number -= 1;
}

export fn main() noreturn {
    // Display port
    io.DDRC.* = 0xFF;
    // PD5 -> first display, PD6 -> second display
    io.DDRD.* |= ((1 << io.PD5) | (1 << io.PD6));

    // Set prescaler = 1024
    io.TCCR1B.* |= bit(io.CS12);
    io.TCCR1B.* &= ~bit(io.CS11);
    io.TCCR1B.* |= bit(io.CS10);

    // Set CTC mode
    io.TCCR1B.* |= bit(io.WGM12);

    // 1 sec
    io.OCR1A.* = 7812;

    io.TIMSK.* |= bit(io.OCIE1A);

    helpers.sei();

    var display = seg7.Seg7(.{
        .pin_g = io.PC7,
        .pin_f = io.PC6,
        .pin_a = io.PC5,
        .pin_b = io.PC4,
    }){ .port = io.PORTC };

    const number_vp: *volatile u8 = &number;

    while (true) {
        var current_bit = START_BIT;
        var local_number = number_vp.*;
        var digits_count = count_digits(local_number);

        for (0..2) |_| {
            io.PORTD.* &= current_bit;
            io.PORTD.* |= current_bit;
            current_bit >>= 1;
            if (digits_count != 0) {
                display.write_digit(seg7.shift_digit(u8, &local_number), false);
                digits_count -= 1;
            } else {
                display.clear();
            }
            helpers.delay_ms(9);
        }
    }
}

fn count_digits(num: u8) u8 {
    if (num == 0) return 1;
    var n = num;
    var count: u8 = 0;
    while (n != 0) : (n /= 10) {
        count += 1;
    }
    return count;
}

comptime {
    const int = @import("interrupt.zig");
    int.export_handlers(.{
        .timer1_compa = &decrement_number,
    });
}
