const std = @import("std");
const io = @import("atmega8535/zig-out/avr_io.zig");
const helpers = @import("helpers.zig");

//
// 7-Segment default pin configuration
// PXN: PX0 .. PX7 - connected port (X -> A, B, C, D)
//
// MCU
//=======
// ... ||
//     ||
// PX7 ||---RRRR-------------------------------+
// PX6 ||---RRRR----------------------------+  |
// PX5 ||---RRRR----------------------+     |  |
// PX4 ||---RRRR-------------------+  | GRN |  |
// PX3 ||---RRRR-------------+     |  |  |  |  |
// PX2 ||---RRRR----------+  |   =================
// PX1 ||---RRRR-------+  |  |   | g  f     a  b |
// PX0 ||---RRRR----+  |  |  |   |               |
//     ||    ^      |  |  |  |   |       8.      |  7-SEGMENT DISPLAY
// ... || resistors |  |  |  |   |               |  (example with common cathode)
//=======           |  |  |  |   | e  d     c dp |
//                  |  |  |  |   =================
//                  |  |  |  |     |  |  |  |  |
//                  |  |  |  ------+  | GRN |  |
//                  |  |  +-----------+     |  |
//                  |  +--------------------+  |
//                  +--------------------------+
//

/// Pin configuration.
/// Contains default configuration for schema above.
pub const Config = struct {
    pin_a: u3 = 6,
    pin_b: u3 = 7,
    pin_c: u3 = 1,
    pin_d: u3 = 2,
    pin_e: u3 = 3,
    pin_f: u3 = 5,
    pin_g: u3 = 4,
    pin_dp: u3 = 0,
    common_anode: bool = false,
};

pub fn Seg7(comptime cfg: Config) type {
    return struct {
        port: *volatile u8,

        const Self = @This();

        pub const pins = [_]u3{ cfg.pin_a, cfg.pin_b, cfg.pin_c, cfg.pin_d, cfg.pin_e, cfg.pin_f, cfg.pin_g };
        pub const dot_pin = cfg.pin_dp;

        pub fn write_digit(self: Self, d: u4, dot: bool) void {
            var pattern = Self.pin_patterns[d];
            if (dot) pattern |= helpers.bit(Self.dot_pin);
            self.port.* = if (cfg.common_anode) ~pattern else pattern;
        }

        pub fn clear(self: Self) void {
            self.port.* = 0x00;
        }

        pub fn put_dot(self: Self) void {
            self.port.* |= helpers.bit(Self.dot_pin);
        }

        // Reversed for correct bit shifting
        pub const digit_patterns = [_]u8 {
            0b00111111, // 0 -> a b c d e f
            0b00000110, // 1 ->   b c
            0b01011011, // 2 -> a b   d e   g
            0b01001111, // 3 -> a b c d     g
            0b01100110, // 4 ->   b c     f g
            0b01101101, // 5 -> a   c d   f g
            0b01111101, // 6 -> a   c d e f g
            0b00000111, // 7 -> a b c
            0b01111111, // 8 -> a b c d e f g
            0b01101111, // 9 -> a b c d   f g
        };

        // Generated pin patterns to write directly to port
        pub const pin_patterns: [16]u8 = blk: {
            var patterns = [_]u8{0} ** 16;
            for (Self.digit_patterns, 0..) |d, i| {
                for (pins, 0..) |p, j| {
                    const pin_state = (d & (1 << j)) != 0;
                    if (pin_state) {
                        patterns[i] |= (1 << p);
                    }
                }
            }
            break :blk patterns;
        };
    };
}

pub const Seg7_Default = Seg7(.{});

pub fn shift_digit(comptime T: type, number: *T) u4 {
    if (@typeInfo(T) != .int) @compileError("Type T must be integer");
    const digit = number.* % 10;
    number.* /= 10;
    return @intCast(digit);
}
