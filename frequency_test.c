#include <avr/io.h>

int main(void) {
    DDRA = 1;
    while (1) {
        PORTA = !(PINA & 1);
    }
    return 0;
}
