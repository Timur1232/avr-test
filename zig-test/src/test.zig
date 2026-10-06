/// This file is for testing generated assembly code
/// Don't use it

const _ = if (!@hasDecl(@import("root"), "__do_not_import")) @compileError("Do not import this file. Only for testing.");

const io = @import("atmega8535/zig-out/avr_io.zig");
const helpers = @import("helpers.zig");

const bit = helpers.bit;

export fn main() noreturn {
    io.DDRC.* = 0xFF;
    io.DDRD.* |= bit(5);
    io.DDRD.* |= bit(6);

    // // Enable internal pull-up resistor.
    // io.PORTD.P2 = 1;
    // // Delay to wait for PD2 become high after enabling pull-up resistor. When MCU is reseted, all pins are grounded by it. If we don't have external pull-up resistor, then it mitgh read low input on that pin. In this case as we setting INT0 to trigger on any logic change, this will trigger interrupt and mess up the logic.
    // helpers.delay_ms(100);

    // INT0 trigger on any logic change
    io.MCUCR.* |= bit(io.ISC00);
    io.MCUCR.* &= ~bit(io.ISC01);

    // Enable INT0
    io.GICR.* |= bit(io.INT0);

    // Set prescaler == 64
    io.TCCR1B.* &= ~bit(io.CS12);
    io.TCCR1B.* |= bit(io.CS11);
    io.TCCR1B.* |= bit(io.CS10);

    // Set CTC mode
    io.TCCR1B.* |= bit(io.WGM12);

    // 8 MHz / 64 = 125000 Hz => 1 tick == 8 mks
    // 1 ms = 1000 mks
    // tick_count = 1000 / 8 = 125
    // subtruct 1 because it counts from zero.
    io.OCR1A.* = 124;

    io.TIMSK.* |= bit(io.OCIE1A);

    // helpers.sei();

    while(true){}
}

const __do_not_import = .{};
