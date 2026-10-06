const std = @import("std");

const helpers = @import("helpers.zig");
const io = @import("io.zig");
const seg7 = @import("seven_segment.zig");

const sei = helpers.sei;
const cli = helpers.cli;

const LED_BLINK_HALF_TIME_MS = 500;
const DISPLAY_SWITCH_DIGIT_TIME_MS = 750;
const BUTTON_HOLD_TIME_MS = 1000;

const Display_State = enum {
    Counter,
    Birthday_Day,
    Birthday_Month,
};

const Globals = struct {
    button_is_pressed: bool = false,
    button_down_timestamp: u32 = 0,

    counter: u8 = 0,

    // 1 - yellow (PD5)
    // 0 - green (PD6)
    current_led: u8 = 1,

    display_state: Display_State = .Counter,
    display_state_switched: bool = false,
    display: seg7.Seg7_Default = undefined,

    milliseconds: u32 = 0,
};

const BIRTHDAY_DAY_INVERTED = 92;
const BIRTHDAY_MONTH_INVERTED = 30;

var g = Globals{};
const g_vp: *volatile Globals = &g;

export fn main() noreturn {
    io.DDRC.set_all();
    io.DDRD.bits.P5 = 1;
    io.DDRD.bits.P6 = 1;

    // // Enable internal pull-up resistor.
    // io.PORTD.P2 = 1;
    // // Delay to wait for PD2 become high after enabling pull-up resistor. When MCU is reseted, all pins are grounded by it. If we don't have external pull-up resistor, then it mitgh read low input on that pin. In this case as we setting INT0 to trigger on any logic change, this will trigger interrupt and mess up the logic.
    // helpers.delay_ms(100);

    // INT0 trigger on any logic change
    io.MCUCR.bits.ISC00 = 1;
    io.MCUCR.bits.ISC01 = 0;

    // Enable INT0
    io.GICR.bits.INT0 = 1;

    // Set prescaler == 64
    io.TCCR1B.bits.CS12 = 0;
    io.TCCR1B.bits.CS11 = 1;
    io.TCCR1B.bits.CS10 = 1;

    // Set CTC mode
    io.TCCR1B.bits.WGM12 = 1;

    // 8 MHz / 64 = 125000 Hz => 1 tick == 8 mks
    // 1 ms = 1000 mks
    // tick_count = 1000 / 8 = 125
    // subtruct 1 because it counts from zero.
    io.OCR1A.* = 124;

    io.TIMSK.bits.OCIE1A = 1;

    sei();

    g.display.port = io.PORTC;
    g.display.write_digit(@intCast(g.counter), false);

    var led_blink_timestamp: u32 = 0;
    var led_light: bool = true;

    var digit_to_send: u4 = @intCast(g.counter);
    var display_switch_digit_timestamp: u32 = 0;
    var birthday: u8 = BIRTHDAY_DAY_INVERTED;
    var digits_count: i8 = -1;

    while (true) {
        const now = now_ms();
        if (g_vp.button_is_pressed and now - g_vp.button_down_timestamp >= BUTTON_HOLD_TIME_MS) {
            if (!g.display_state_switched) {
                g.display_state_switched = true;
                g.display.clear();
                g.display.put_dot();
                switch (g.display_state) {
                    .Counter => {
                        g.display_state = .Birthday_Day;
                        birthday = BIRTHDAY_DAY_INVERTED;
                    },
                    .Birthday_Day => {
                        g.display_state = .Birthday_Month;
                        birthday = BIRTHDAY_MONTH_INVERTED;
                    },
                    .Birthday_Month => {
                        g.display_state = .Counter;
                    },
                }
                digits_count = -1;
            }
        } else {
            g.display_state_switched = false;
            if (g.display_state == .Counter) {
                digit_to_send = @intCast(g_vp.counter);
            } else if (now - display_switch_digit_timestamp >= DISPLAY_SWITCH_DIGIT_TIME_MS) {
                display_switch_digit_timestamp = now;
                if (birthday == 0) {
                    if (g.display_state == .Birthday_Day) birthday = BIRTHDAY_DAY_INVERTED;
                    if (g.display_state == .Birthday_Month) birthday = BIRTHDAY_MONTH_INVERTED;
                    digits_count = -1;
                }
                digit_to_send = seg7.shift_digit(u8, &birthday);
                digits_count += 1;
            }
            g.display.write_digit(digit_to_send, digits_count == 0);
        }

        if (now - led_blink_timestamp >= LED_BLINK_HALF_TIME_MS * (@as(u32, g_vp.current_led) + 1)) {
            led_blink_timestamp = now;
            led_light = !led_light;
        }

        if (led_light) {
            if (g_vp.current_led == 1) {
                io.PORTD.bits.P5 = 1;
                io.PORTD.bits.P6 = 0;
            } else {
                io.PORTD.bits.P6 = 1;
                io.PORTD.bits.P5 = 0;
            }
        } else {
            io.PORTD.bits.P5 = 0;
            io.PORTD.bits.P6 = 0;
        }
    }
}

fn now_ms() u32 {
    return g_vp.milliseconds;
}

fn int0() callconv(.avr_signal) void {
    if (io.PIND.is_set(2)) {
        // Button up
        if (!g.display_state_switched and g.display_state == .Counter) {
            g.counter += 1;
            if (g.counter > 9) {
                g.counter = 0;
            }
            g.display.write_digit(@intCast(g.counter), false);
        }

        g.button_is_pressed = false;
        g.current_led = 1 - g.current_led;
    } else {
        g.button_is_pressed = true;
        g.button_down_timestamp = now_ms();
    }
}

fn timer1_compa() callconv(.avr_signal) void {
    g.milliseconds += 1;
}

comptime {
    const int = @import("interrupt.zig");
    int.export_handlers(.{
        .int0 = &int0,
        .timer1_compa = &timer1_compa,
    });
}
