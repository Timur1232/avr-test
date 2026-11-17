#define BAUD 9600

#include <avr/io.h>
#include <util/delay.h>
#include <util/setbaud.h>

#include <stdbool.h>

void usart_transmit_byte(unsigned char data) {
    // Wait for transmit register empty
    while (!(UCSRA & (1 << UDRE)));
    // Put data in register and send it
    UDR = data;
}

void usart_transmit_string(char *str) {
    while (*str) {
        usart_transmit_byte(*str);
        str += 1;
    }
}

int main() {
    // Set baud rate
    UBRRH = UBRRH_VALUE;
    UBRRL = UBRRL_VALUE;

    // Enable transmittor
    UCSRB = (1 << TXEN) | (1 << RXEN);

    // Set frame format: 8 bits for data and 1 stop bits
    UCSRC = (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0);

    while (true) {
        usart_transmit_string("Hello from ATMega8535!\r\n");
        _delay_ms(1000);
    }
}
