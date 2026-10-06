const Interrupt_Fn = ?*const fn () callconv(.avr_signal) void;

pub const Vectors_Table = extern struct {
    int0:         Interrupt_Fn = null, // IRQ0 Handler
    int1:         Interrupt_Fn = null, // IRQ1 Handler
    timer2_comp:  Interrupt_Fn = null, // Timer2 Compare Handler
    timer2_ovf:   Interrupt_Fn = null, // Timer2 Overflow Handler
    timer1_capt:  Interrupt_Fn = null, // Timer1 Capture Handler
    timer1_compa: Interrupt_Fn = null, // Timer1 Compare A Handler
    timer1_compb: Interrupt_Fn = null, // Timer1 Compare B Handler
    timer1_ovf:   Interrupt_Fn = null, // Timer1 Overflow Handler
    timer0_ovf:   Interrupt_Fn = null, // Timer0 Overflow Handler
    spi_stc:      Interrupt_Fn = null, // SPI Transfer Complete Handler
    usart_rxc:    Interrupt_Fn = null, // USART RX Complete Handler
    usart_udre:   Interrupt_Fn = null, // UDR Empty Handler
    usart_txc:    Interrupt_Fn = null, // USART TX Complete Handler
    adc:          Interrupt_Fn = null, // ADC Conversion Complete Handler
    ee_rdy:       Interrupt_Fn = null, // EEPROM Ready Handler
    ana_comp:     Interrupt_Fn = null, // Analog Comparator Handler
    twsi:         Interrupt_Fn = null, // Two-wire Serial Interface Handler
    int2:         Interrupt_Fn = null, // IRQ2 Handler
    timer0_comp:  Interrupt_Fn = null, // Timer0 Compare Handler
    spm_rdy:      Interrupt_Fn = null, // Store Program Memory Ready Handler
};

const std = @import("std");

pub fn export_handlers(comptime handlers: Vectors_Table) void {
    inline for (@typeInfo(Vectors_Table).@"struct".fields, 0..) |field, index| {
        const handler = @field(handlers, field.name);
        if (handler != null) {
            const name = std.fmt.comptimePrint("__vector_{}", .{index + 1});
            @export(handler.?, .{ .name = name, .linkage = .strong });
        }
    }
}
