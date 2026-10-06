#include <avr/io.h>

#define SEVEN_SEGMENT_IMPLEMENTATION
#include "libs/seven_segment.h"

// Arbitrary values
#define DEBOUNCE_DELAY_ITERATIONS 10000
#define BLINK_TIMES_ITERATIONS    40000
#define BUTTON_PRESS_DELAY        70000

typedef enum : int {
    Led_Color_Yellow = 0,
    Led_Color_Green  = 1,
} Led_Color;

typedef enum : int {
    Display_State_Counter,
    Display_State_Birthday_Day,
    Display_State_Birthday_Month,
} Display_State;

int main(void) {
    DDRC = 0xFF;
    DDRD |= ((1 << PD5) | (1 << PD6));

    int button_is_pressed = 0;
    // Button press state on previous iteration (for detecting up event).
    int button_is_pressed_on_previous_frame = 0;
    // Timer for programmatically disabling button pressing to avoid button rettle.
    // long int debounce_delay = 0;
    // Cycle iterations of button being pressed.
    long int button_press_iterations = 0;

    // Showed up on 7-segment display.
    unsigned char counter = 0;
    // What LED currently blinking:
    //   0 -> yellow
    //   1 -> green
    Led_Color led_color = Led_Color_Yellow;
    long int blink_timer = BLINK_TIMES_ITERATIONS;
    int led_on = 0;

    PORTC = seg7_single_digit_port_value(counter, 0);
    Display_State display_state = Display_State_Counter;
    int birthday_digit = 0;
    int switched = 0;

    while (1) {
        // Signal coming from button (Pin PD7).
        // Button is triggered low.
        int button_signal = !(PIND & (1 << PD2));

        if (button_signal && !button_is_pressed) {
            button_is_pressed = 1;
        } else if (!button_signal) {
            button_is_pressed = 0;
        }

        if (button_is_pressed) {
            PORTD &= ~((1 << PD5) | (1 << PD6));
            button_press_iterations++;
            if (switched) {
                PORTC = seg7_single_digit_port_value(-1, 1);
            }
        } else if (button_is_pressed_on_previous_frame) { // Button up effectively
            blink_timer = 0;
            button_press_iterations = 0;

            if (!switched) {
                led_color = !led_color;
                button_press_iterations = 0;

                if (display_state == Display_State_Counter) {
                    counter += 1;
                    if (counter > 9) {
                        counter = 0;
                    }
                    PORTC = seg7_single_digit_port_value(counter, 0);
                }
            } else {
                switched = 0;
                if (display_state == Display_State_Counter) {
                    PORTC = seg7_single_digit_port_value(counter, 0);
                }
            }
        }

        button_is_pressed_on_previous_frame = button_is_pressed;
        blink_timer--;
        if (blink_timer <= 0) {
            blink_timer = BLINK_TIMES_ITERATIONS * (led_color + 1);
            led_on = !led_on;
            // yellow (0) -> PD5, green (1) -> PD6
            PORTD &= ~((1 << PD5) | (1 << PD6));
            if (led_on) {
                PORTD |= (1 << (PD5 + led_color));
            }

            switch (display_state) {
            case Display_State_Birthday_Day:
                if (birthday_digit) {
                    PORTC = seg7_single_digit_port_value(2, 0);
                } else {
                    PORTC = seg7_single_digit_port_value(9, 0);
                }
                birthday_digit = !birthday_digit;
                break;
            case Display_State_Birthday_Month:
                if (birthday_digit) {
                    PORTC = seg7_single_digit_port_value(0, 0);
                } else {
                    PORTC = seg7_single_digit_port_value(3, 0);
                }
                birthday_digit = !birthday_digit;
                break;
            default: break;
            }
        }

        if (!switched && button_press_iterations >= BUTTON_PRESS_DELAY) {
            switch (display_state) {
            case Display_State_Counter:        display_state = Display_State_Birthday_Day;   break;
            case Display_State_Birthday_Day:   display_state = Display_State_Birthday_Month; break;
            case Display_State_Birthday_Month:
                display_state = Display_State_Counter;
                PORTC = seg7_single_digit_port_value(counter, 0);
                break;
            }
            switched = 1;
        }
    }
}
