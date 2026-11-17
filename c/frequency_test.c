#include <avr/io.h>

int main(void) {
    DDRD |= (1 << PD7);
    while (1) {
        PORTD ^= (1 << PD7);
    }
    return 0;
}
