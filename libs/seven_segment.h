#ifndef _SEVEN_SEGMENT_H_
#define _SEVEN_SEGMENT_H_

#include <stdint.h>
#include <stdbool.h>

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

// Below are setters for corresponding segments for default pin configuration drawn above.
// You can redefine this for different configurations by setting pin indeces like so:
// `#define SEG7_PIN_<X> <N>`
// where <X> is desired segment (A..F or DOT) and <N> is pin (bit) index.

#ifndef SEG7_PIN_A
#   define SEG7_PIN_A 6
#endif // SEG7_PIN_A

#ifndef SEG7_PIN_B
#   define SEG7_PIN_B 7
#endif // SEG7_PIN_B

#ifndef SEG7_PIN_C
#   define SEG7_PIN_C 1
#endif // SEG7_PIN_C

#ifndef SEG7_PIN_D
#   define SEG7_PIN_D 2
#endif // SEG7_PIN_D

#ifndef SEG7_PIN_E
#   define SEG7_PIN_E 3
#endif // SEG7_PIN_E

#ifndef SEG7_PIN_F
#   define SEG7_PIN_F 5
#endif // SEG7_PIN_F

#ifndef SEG7_PIN_G
#   define SEG7_PIN_G 4
#endif // SEG7_PIN_G

#ifndef SEG7_PIN_DOT
#   define SEG7_PIN_DOT 0
#endif // SEG7_PIN_DOT

// Bit setters
#define SEG7_SET_A(var) (var |= (1 << SEG7_PIN_A))
#define SEG7_SET_B(var) (var |= (1 << SEG7_PIN_B))
#define SEG7_SET_C(var) (var |= (1 << SEG7_PIN_C))
#define SEG7_SET_D(var) (var |= (1 << SEG7_PIN_D))
#define SEG7_SET_E(var) (var |= (1 << SEG7_PIN_E))
#define SEG7_SET_F(var) (var |= (1 << SEG7_PIN_F))
#define SEG7_SET_G(var) (var |= (1 << SEG7_PIN_G))
#define SEG7_SET_DOT(var) (var |= (1 << SEG7_PIN_DOT))

// For example, can be set to `#define SEG7_DEF static inline`
#ifndef SEG7_DEF
#   define SEG7_DEF
#endif // SEG7_DEF

// Get bits for digit with specifiying dot to directly write to port.
// This function will you bit setters from above.
//
// Example:
// ```c
// PORTC = seg7_single_digit_port_value(5, false);
// ```
SEG7_DEF uint8_t seg7_single_digit_port_value(uint8_t digit, bool dot);

// Shifts one last digit of a decimal number.
// Will write to variables `number` and `shifted_digit`.
//
// Warning: This macro uses integer division operations - use with caution.
//
// Example:
// ```c
// int number = 69;
// uint8_t digit;
// seg7_shift_digit(number, digit);
// // number == 6, digit == 9
// ```
#define seg7_shift_digit(number, shifted_digit) do { \
        shifted_digit = number % 10;                 \
        number /= 10;                                \
    } while (0)

#endif // _SEVEN_SEGMENT_H_

#ifdef SEG7_IMPLEMENTATION
// 0 -> a b c d e f
// 1 ->   b c
// 2 -> a b   d e   g
// 3 -> a b c d     g
// 4 ->   b c     f g
// 5 -> a   c d   f g
// 6 -> a   c d e f g
// 7 -> a b c
// 8 -> a b c d e f g
// 9 -> a b c d   f g
SEG7_DEF uint8_t seg7_single_digit_port_value(uint8_t digit, bool dot) {
    uint8_t port_val = 0;
    if (dot) {
        SEG7_SET_DOT(port_val);
    }
    if (digit > 9) {
        return port_val;
    }
    if (   digit == 0
        || digit == 2
        || digit == 3
        || (digit >= 5 && digit <= 9)) {
        SEG7_SET_A(port_val);
    }
    if (digit != 5 && digit != 6) {
        SEG7_SET_B(port_val);
    }
    if (digit != 2) {
        SEG7_SET_C(port_val);
    }
    if (digit != 1 && digit != 7 && digit != 4) {
        SEG7_SET_D(port_val);
    }
    if (digit == 0 || digit == 2 || digit == 6 || digit == 8) {
        SEG7_SET_E(port_val);
    }
    if (!(digit >= 1 && digit <= 3) && digit != 7) {
        SEG7_SET_F(port_val);
    }
    if (digit != 0 && digit != 1 && digit != 7) {
        SEG7_SET_G(port_val);
    }
    return port_val;
}
#endif // SEVEN_SEGMENT_IMPLEMENTATION
