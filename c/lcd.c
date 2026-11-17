#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include <stdbool.h>

#define SET_RS() do { PORTA |= (1 << PA7); } while(0)
#define CLEAR_RS() do { PORTA &= ~(1 << PA7); } while(0)

#define SET_RW() do { PORTA |= (1 << PA6); } while(0)
#define CLEAR_RW() do { PORTA &= ~(1 << PA6); } while(0)

#define SET_E() do { PORTA |= (1 << PA5); } while(0)
#define CLEAR_E() do { PORTA &= ~(1 << PA5); } while(0)

void lcd_send_long_command() {
    SET_E();
    _delay_us(1);
    CLEAR_E();
    _delay_ms(2);
}

void lcd_send_short_command() {
    SET_E();
    _delay_us(1);
    CLEAR_E();
    _delay_us(38);
}

void lcd_clear_display() {
    PORTC = (1 << PC0);
    lcd_send_long_command();
}

void lcd_return_home() {
    PORTC = (1 << PC1);
    lcd_send_long_command();
}

void lcd_send_char(char ch) {
    SET_RS();
    PORTC = ch;
    lcd_send_short_command();
    CLEAR_RS();
}

void lcd_second_line() {
    PORTC = (1 << PC7) | (1 << PC6);
    lcd_send_short_command();
}

void lcd_send_string(const char* ch) {
    while (*ch) {
        if (*ch == '\n') {
            lcd_second_line();
        } else {
            lcd_send_char(*ch);
        }
        ch++;
    }
}

int main() {
    cli();
    DDRC = 0xFF;
    DDRA |= (1 << PA7) | (1 << PA6) | (1 << PA5);

    // Set function: 8-bit mode, 2 lines, 5x8 dots font
    PORTC = (1 << PC5) | (1 << PC4) | (1 << PC3);
    lcd_send_short_command();

    // Set display control: display on, cursor on, cursor not blink
    PORTC = (1 << PC3) | (1 << PC2) | (1 << PC1);
    lcd_send_short_command();

    // Set entry mode: cursor increment on write, display shift off
    PORTC = (1 << PC2) | (1 << PC1);
    lcd_send_short_command();

    lcd_return_home();
    lcd_clear_display();

    lcd_send_string("Hello World!\n");
    lcd_send_string("yay :D");

    DDRB = 0xFF;

    while (true) {
        PORTB = 0x55;
        _delay_ms(500);
        PORTB = 0xAA;
        _delay_ms(500);
    }
}
