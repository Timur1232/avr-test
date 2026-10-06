#include <avr/io.h>

int main() {
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

    // sei();

    while (1) {
        __asm__ volatile ("nop");
    }
    return 0;
}
