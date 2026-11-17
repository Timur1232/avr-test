#include <avr/io.h>
#include <avr/interrupt.h>

#include <stdbool.h>
#include <stdint.h>

#define SEG7_IMPLEMENTATION
#include "libs/seven_segment.h"


volatile uint32_t milliseconds = 0;
uint32_t now_ms() {
    uint32_t m;
    cli();
    m = milliseconds;
    sei();
    return m;
}

#define LED_BLINK_HALF_TIME_MS 500
#define DISPLAY_SWITCH_DIGIT_TIME_MS 750
#define BUTTON_HOLD_TIME_MS 1000


typedef enum : uint8_t {
    Display_State_Counter,
    Display_State_Birthday_Day,
    Display_State_Birthday_Month,
} Display_State;

#define BIRTHDAY_DAY_INVERTED 92
#define BIRTHDAY_MONTH_INVERTED 30


volatile bool button_is_pressed = false;
volatile uint32_t button_down_timestamp = 0;

volatile uint8_t counter = 0;

// 1 - yellow (PD5)
// 0 - green (PD6)
volatile uint8_t current_led = 1;

volatile Display_State display_state = Display_State_Counter;
volatile bool display_state_switched = false;

int main(void) {
    DDRC = 0xFF;
    DDRD |= ((1 << PD5) | (1 << PD6));

    // INT0 trigger on any logic change
    MCUCR |= (1 << ISC00);
    MCUCR &= ~(1 << ISC01);

    // Enable INT0
    GICR |= (1 << INT0);

    // Set prescaler == 64
    TCCR1B &= ~(1 << CS12);
    TCCR1B |= (1 << CS11);
    TCCR1B |= (1 << CS10);

    // Set CTC mode
    TCCR1B |= (1 << WGM12);

    // 8 MHz / 64 = 125000 Hz => 1 tick == 8 mks
    // 1 ms = 1000 mks
    // tick_count = 1000 / 8 = 125
    // subtruct 1 because it counts from zero.
    OCR1A = 124;

    TIMSK |= (1 << OCIE1A);

    PORTC = seg7_single_digit_port_value(counter, false);

    sei();

    uint32_t led_blink_timestamp = 0;
    bool led_light = true;

    uint8_t digit_to_send = counter;
    uint32_t display_switch_digit_timestamp = 0;
    uint8_t birthday = BIRTHDAY_DAY_INVERTED;
    int8_t digits_count = -1;

    while (1) {
        uint32_t now = now_ms();
        if (button_is_pressed && now - button_down_timestamp >= BUTTON_HOLD_TIME_MS) {
            if (!display_state_switched) {
                display_state_switched = true;
                PORTC = seg7_single_digit_port_value(-1, true);
                switch (display_state) {
                    case Display_State_Counter:
                        display_state = Display_State_Birthday_Day;
                        birthday = BIRTHDAY_DAY_INVERTED;
                        break;
                    case Display_State_Birthday_Day:
                        display_state = Display_State_Birthday_Month;
                        birthday = BIRTHDAY_MONTH_INVERTED;
                        break;
                    case Display_State_Birthday_Month:
                        display_state = Display_State_Counter;
                        break;
                }
                digits_count = -1;
            }
        } else {
            display_state_switched = false;
            if (display_state == Display_State_Counter) {
                digit_to_send = counter;
            } else if (now - display_switch_digit_timestamp >= DISPLAY_SWITCH_DIGIT_TIME_MS) {
                display_switch_digit_timestamp = now;
                if (!birthday) {
                    if (display_state == Display_State_Birthday_Day) birthday = BIRTHDAY_DAY_INVERTED;
                    if (display_state == Display_State_Birthday_Month) birthday = BIRTHDAY_MONTH_INVERTED;
                    digits_count = -1;
                }
                seg7_shift_digit(birthday, digit_to_send);
                digits_count++;
            }
            PORTC = seg7_single_digit_port_value(digit_to_send, digits_count == 0);
        }

        if (now - led_blink_timestamp >= LED_BLINK_HALF_TIME_MS * ((uint32_t)current_led + 1)) {
            led_blink_timestamp = now;
            led_light = !led_light;
        }

        if (led_light) {
            if (current_led) {
                PORTD |= (1 << PD5);
                PORTD &= ~(1 << PD6);
            } else {
                PORTD |= (1 << PD6);
                PORTD &= ~(1 << PD5);
            }
        } else {
            PORTD &= ~((1 << PD5) | (1 << PD6));
        }
    }
}

ISR(INT0_vect) {
    if (PIND & (1 << PD2)) {
        // Button up
        if (!display_state_switched && display_state == Display_State_Counter) {
            counter += 1;
            if (counter > 9) {
                counter = 0;
            }
            PORTC = seg7_single_digit_port_value(counter, false);
        }

        button_is_pressed = false;
        // PORTD &= ~(1 << (PD5 + current_led));
        current_led = !current_led;
    } else {
        button_is_pressed = true;
        button_down_timestamp = now_ms();
    }
}

ISR(TIMER1_COMPA_vect) {
    milliseconds++;
}
