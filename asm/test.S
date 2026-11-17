#include <avr/io.h>

#define IO(x) _SFR_IO_ADDR(x)

.section .progmem
hello_str: .asciz "Hello World!\r\n"
sine: .byte 128, 140, 153, 165, 177, 188, 199, 209, 218, 227, 234, 240, 246, 250, 253, 255, 255, 255, 253, 250, 246, 240, 234, 227, 218, 209, 199, 188, 177, 165, 153, 140, 128, 116, 103, 91, 79, 68, 57, 47, 38, 29, 22, 16, 10, 6, 3, 1, 0, 1, 3, 6, 10, 16, 22, 29, 38, 47, 57, 68, 79, 91, 103, 116

.section .text

.global main
main:
    ; Set clock prescaler to 1
    ldi r16, _BV(CLKPCE)
    out IO(CLKPR), r16
    ldi r16, 0
    out IO(CLKPR), r16

    ; Set PB0 (PWM) to output
    sbi IO(DDRB), DDB0
    ; Set PB4 (UART) to output
    sbi IO(DDRB), DDB4

    ; Set PB4 high for UART Idle
    sbi IO(PORTB), PB4

    rcall set_timer_for_uart

    ldi r30, lo8(hello_str)
    ldi r31, hi8(hello_str)

    sei

main_loop:

    rcall uart_send_string

    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay
    rcall delay

    rjmp main_loop


; Setting timer for PWM with passed duty cycle
;
; Parameters:
; r17 - duty cycle (0 - 255 => 0% - 100%)
set_timer_for_pwm:
    push r16
    clr r16

    ; Set mode 3 (Fast PWM), clear OC0A on compare match and set OC0A at TOP
    ldi r16, _BV(WGM01) | _BV(WGM00) | _BV(COM0A1)
    out IO(TCCR0A), r16

    ; Set prescaler to 1
    ldi r16, _BV(CS00)
    out IO(TCCR0B), r16

    ; Set PWM duty cycle
    out IO(OCR0A), r17

    pop r16
    ret


; Setting timer for uart communication
set_timer_for_uart:
    push r16
    clr r16

    ; Baud rate ~ 9600: OCR0A = (9.6 MGz / (8 * 9600)) - 1 = 124.
    ; This solution is using internal 9.6 MGz oscillator, wich is inpercise. Value 121 is obtained by manual testing with oscillograph.
    ldi r16, 121
    out IO(OCR0A), r16

    ; Set mode 2 (CTC)
    ldi r16, _BV(WGM01)
    out IO(TCCR0A), r16

    ; Set prescaler to 8
    ldi r16, _BV(CS01)
    out IO(TCCR0B), r16

    pop r16
    ret


; Sends one byte to PB4 by UART
;
; PB4 must be set as output
;
; Parameters:
; r17 - byte to send
uart_send_byte:
    push r17
    push r18
    push r16

    ldi r18, _BV(OCF0A)
    out IO(TIFR0), r18

    clr r18
    out IO(TCNT0), r18

    ldi r16, 11 ; Uart counter: start, data bits, stop bits. It is 11 and not 10, because we need to give one tick for stop bit. Otherwise it would be instant and packet will be corrupted.
    ldi r18, _BV(OCIE0A)
    out IO(TIMSK0), r18

    ; Wait for timer interrupt to send all bytes
uart_send_byte_loop:
    cpi r16, 0
    brne uart_send_byte_loop

    pop r16
    pop r18
    pop r17
    ret


; Sending Z string via UART.
;
; Parameters:
; Z (r31:r30) - base pointer to Z string
uart_send_string:
    push r30
    push r31
    push r17

uart_send_string_loop:
    lpm r17, Z+
    tst r17
    breq uart_send_string_done
    rcall uart_send_byte
    rjmp uart_send_string_loop

uart_send_string_done:
    pop r17
    pop r31
    pop r30
    ret





; Timer Comare A interrupt. Sends single bit from r17 to port PB4. Register r16 must be set to 8 before enabling timer for uart - it is used as bit counter.
;
; PB4 must be set as output
;
; Parameters:
; r16 (implicit) - how many bits left. Used as global state.
; r17 (implicit) - byte to send. Used as global state.
.global TIM0_COMPA_vect
TIM0_COMPA_vect:
    in r0, IO(SREG)
    push r0

    ; r16 = 11 -> start
    ; r16 = 10..3 -> data (b0..b7)
    ; r16 = 2 -> stop
    ; r16 = 1 -> uart off
    cpi r16, 11
    breq TIM0_COMPA_vect_uart_start
    cpi r16, 2
    breq TIM0_COMPA_vect_uart_stop
    cpi r16, 1
    breq TIM0_COMPA_vect_uart_off
    cpi r16, 0
    breq TIM0_COMPA_vect_uart_done

TIM0_COMPA_vect_uart_data:
    sbrc r17, 0          ; if bit0 = 0, skip sbi
    sbi IO(PORTB), PB4
    sbrs r17, 0          ; if bit0 = 1, skip cbi
    cbi IO(PORTB), PB4
    lsr r17              ; next bit -> bit0
    dec r16
    rjmp TIM0_COMPA_vect_uart_done

TIM0_COMPA_vect_uart_start:
    cbi IO(PORTB), PB4   ; start bit = 0
    dec r16              ; 11 -> 10
    rjmp TIM0_COMPA_vect_uart_done

TIM0_COMPA_vect_uart_stop:
    sbi IO(PORTB), PB4   ; stop bit = 1
    dec r16              ; 2 -> 1
    rjmp TIM0_COMPA_vect_uart_done

TIM0_COMPA_vect_uart_off:
    ; Turn off OCF0A interrupt
    clr r17
    out IO(TIMSK0), r17
    clr r16

TIM0_COMPA_vect_uart_done:
    pop r0
    out IO(SREG), r0
    reti


delay:
    ldi r20, 0xFF
delay_loop1:
    ldi r21, 0xFF
delay_loop2:
    dec r21
    brne delay_loop2
    dec r20
    brne delay_loop1
    ret
