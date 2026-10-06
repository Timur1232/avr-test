#include <avr/io.h>
#include <util/delay.h>

void shifting_led(void) {
    DDRC = 0xFF;

    PORTC = 1;
    while (1) {
        PORTC <<= 1;
        if (PORTC == 0) {
            PORTC = 1;
        }
        _delay_ms(250);
    }
}


void alternate_led(void) {
    DDRC = 0xFF;

    int state = 0;
    while (1) {
        if (state) {
            PORTC = 0xAA;
        } else {
            PORTC = 0x55;
        }
        state = !state;
        _delay_ms(500);
    }
}


int main(void) {
    shifting_led();
    return 0;
}
