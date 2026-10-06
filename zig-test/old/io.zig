const std = @import("std");
const helpers = @import("helpers.zig");

pub const IO_OFFSET = 0x20;

pub fn io_map(io_addr: comptime_int, comptime T: type) *volatile T {
    return @ptrFromInt(io_addr + IO_OFFSET);
}

pub inline fn raw(comptime Backing_Int: type, ptr: *anyopaque) *Backing_Int {
    return @ptrCast(ptr);
}

pub fn Io_Register(comptime Bits: anytype) type {
    const bits_info = @typeInfo(Bits);
    const Backing_Int = blk: switch (bits_info) {
        .@"struct" => |s| {
            if (s.layout != .@"packed") {
                @compileError(std.fmt.comptimePrint("Bits type must be packed struct, got: {}", .{s.layout}));
            }
            break :blk s.backing_integer.?;
        },
        else => @compileError(std.fmt.comptimePrint("Bits type must be packed struct, but got: {}", .{Bits})),
    };
    return packed struct {
        bits: Bits,

        const Self = @This();

        pub inline fn set(self: *volatile Self, bit: c_int) void {
            self.raw().* |= @as(Backing_Int, 1) << bit;
        }

        pub inline fn clear(self: *volatile Self, bit: c_int) void {
            self.raw().* &= ~(@as(Backing_Int, 1) << bit);
        }

        pub inline fn set_mask(self: *volatile Self, mask: Backing_Int) void {
            self.raw().* |= mask;
        }

        pub inline fn clear_mask(self: *volatile Self, mask: Backing_Int) void {
            self.raw().* &= ~mask;
        }

        pub inline fn raw(self: *volatile Self) *volatile Backing_Int {
            return @ptrCast(&self.bits);
        }

        pub inline fn set_all(self: *volatile Self) void {
            self.raw().* = std.math.maxInt(Backing_Int);
        }

        pub inline fn clear_all(self: *volatile Self) void {
            self.raw().* = 0x0;
        }

        pub inline fn is_set(self: *volatile Self, bit: c_int) bool {
            return self.raw().* & (@as(Backing_Int, 1) << bit) != 0;
        }
    };
}

pub const Port_Register = Io_Register(packed struct { P0: u1, P1: u1, P2: u1, P3: u1, P4: u1, P5: u1, P6: u1, P7: u1 });

pub const PORTA = io_map(0x1B, Port_Register);
pub const DDRA  = io_map(0x1A, Port_Register);
pub const PINA  = io_map(0x19, Port_Register);

pub const PORTB = io_map(0x18, Port_Register);
pub const DDRB  = io_map(0x17, Port_Register);
pub const PINB  = io_map(0x16, Port_Register);

pub const PORTC = io_map(0x15, Port_Register);
pub const DDRC  = io_map(0x14, Port_Register);
pub const PINC  = io_map(0x13, Port_Register);

pub const PORTD = io_map(0x12, Port_Register);
pub const DDRD  = io_map(0x11, Port_Register);
pub const PIND  = io_map(0x10, Port_Register);

pub const MCUCR = io_map(0x35, Io_Register(packed struct {
    ISC00: u1,
    ISC01: u1,
    ISC10: u1,
    ISC11: u1,
    SM0: u1,
    SM1: u1,
    SE: u1,
    SM2: u1,
}));

pub const GICR = io_map(0x3B, Io_Register(packed struct {
    IVCE: u1,
    ICSEL: u1,
    @"-": u3,
    INT2: u1,
    INT0: u1,
    INT1: u1,
}));

pub const GIFR = io_map(0x3A, Io_Register(packed struct {
    @"-": u5,
    INTF2: u1,
    INTF0: u1,
    INTF1: u1,
}));

pub const TCCR1A = io_map(0x2F, Io_Register(packed struct {
    WGM10: u1,
    WGM11: u1,
    FOC1B: u1,
    FOC1A: u1,
    COM1B0: u1,
    COM1B1: u1,
    COM1A0: u1,
    COM1A1: u1,
}));

pub const TCCR1B = io_map(0x2E, Io_Register(packed struct {
    CS10: u1,
    CS11: u1,
    CS12: u1,
    WGM12: u1,
    WGM13: u1,
    @"-": u1,
    ICES1: u1,
    ICNC1: u1,
}));

pub const OCR1A = io_map(0x2A, u16);

pub const TIMSK = io_map(0x39, Io_Register(packed struct {
    TOIE0: u1,
    OCIE0: u1,
    TOIE1: u1,
    OCIE1B: u1,
    OCIE1A: u1,
    TICIE1: u1,
    TOIE2: u1,
    OCIE2: u1,
}));

pub const P0 = 0;
pub const P1 = 1;
pub const P2 = 2;
pub const P3 = 3;
pub const P4 = 4;
pub const P5 = 5;
pub const P6 = 6;
pub const P7 = 7;

// The Register Bit names are represented by their bit number (0-7).

// General Interrupt Control Register
pub const INT1 = 7;
pub const INT0 = 6;
pub const INT2 = 5;
pub const IVSEL = 1;
pub const IVCE = 0;

// General Interrupt Flag Register
pub const INTF1 = 7;
pub const INTF0 = 6;
pub const INTF2 = 5;

// Timer/Counter Interrupt MaSK register
pub const OCIE2 = 7;
pub const TOIE2 = 6;
pub const TICIE1 = 5;
pub const OCIE1A = 4;
pub const OCIE1B = 3;
pub const TOIE1 = 2;
pub const OCIE0 = 1;
pub const TOIE0 = 0;

// Timer/Counter Interrupt Flag register
pub const OCF2 = 7;
pub const TOV2 = 6;
pub const ICF1 = 5;
pub const OCF1A = 4;
pub const OCF1B = 3;
pub const TOV1 = 2;
pub const OCF0 = 1;
pub const TOV0 = 0;

// Store Program Memory Control Register
pub const SPMIE = 7;
pub const RWWSB = 6;
pub const RWWSRE = 4;
pub const BLBSET = 3;
pub const PGWRT = 2;
pub const PGERS = 1;
pub const SPMEN = 0;

// TWI Control Register
pub const TWINT = 7;
pub const TWEA = 6;
pub const TWSTA = 5;
pub const TWSTO = 4;
pub const TWWC = 3;
pub const TWEN = 2;
pub const TWIE = 0;

// MCU Control Register
pub const SM2 = 7;
pub const SE = 6;
pub const SM1 = 5;
pub const SM0 = 4;
pub const ISC11 = 3;
pub const ISC10 = 2;
pub const ISC01 = 1;
pub const ISC00 = 0;

// MCU Control and Status Register
pub const ISC2 = 6;
pub const WDRF = 3;
pub const BORF = 2;
pub const EXTRF = 1;
pub const PORF = 0;

// Timer/Counter 0 Control Register
pub const FOC0 = 7;
pub const WGM00 = 6;
pub const COM01 = 5;
pub const COM00 = 4;
pub const WGM01 = 3;
pub const CS02 = 2;
pub const CS01 = 1;
pub const CS00 = 0;

// The ADHSM bit has been removed from all documentation,
// as being not needed at all since the comparator has proven
// to be fast enough even without feeding it more power.

// Special Function IO Register
pub const ADTS2 = 7;
pub const ADTS1 = 6;
pub const ADTS0 = 5;
pub const ACME = 3;
pub const PUD = 2;
pub const PSR2 = 1;
pub const PSR10 = 0;

// Timer/Counter 1 Control Register
pub const COM1A1 = 7;
pub const COM1A0 = 6;
pub const COM1B1 = 5;
pub const COM1B0 = 4;
pub const FOC1A = 3;
pub const FOC1B = 2;
pub const WGM11 = 1;
pub const WGM10 = 0;

// Timer/Counter 1 Control and Status Register
pub const ICNC1 = 7;
pub const ICES1 = 6;
pub const WGM13 = 4;
pub const WGM12 = 3;
pub const CS12 = 2;
pub const CS11 = 1;
pub const CS10 = 0;

// Timer/Counter 2 Control Register
pub const FOC2 = 7;
pub const WGM20 = 6;
pub const COM21 = 5;
pub const COM20 = 4;
pub const WGM21 = 3;
pub const CS22 = 2;
pub const CS21 = 1;
pub const CS20 = 0;

// Asynchronous mode Status Register
pub const AS2 = 3;
pub const TCN2UB = 2;
pub const OCR2UB = 1;
pub const TCR2UB = 0;

// Watchdog Timer Control Register
pub const WDCE = 4;
pub const WDE = 3;
pub const WDP2 = 2;
pub const WDP1 = 1;
pub const WDP0 = 0;

// USART Control and Status Register C
pub const URSEL = 7;
pub const UMSEL = 6;
pub const UPM1 = 5;
pub const UPM0 = 4;
pub const USBS = 3;
pub const UCSZ1 = 2;
pub const UCSZ0 = 1;
pub const UCPOL = 0;

// Data Register, Port A
pub const PA7 = 7;
pub const PA6 = 6;
pub const PA5 = 5;
pub const PA4 = 4;
pub const PA3 = 3;
pub const PA2 = 2;
pub const PA1 = 1;
pub const PA0 = 0;

// Data Direction Register, Port A
pub const DDA7 = 7;
pub const DDA6 = 6;
pub const DDA5 = 5;
pub const DDA4 = 4;
pub const DDA3 = 3;
pub const DDA2 = 2;
pub const DDA1 = 1;
pub const DDA0 = 0;

// Input Pins, Port A
pub const PINA7 = 7;
pub const PINA6 = 6;
pub const PINA5 = 5;
pub const PINA4 = 4;
pub const PINA3 = 3;
pub const PINA2 = 2;
pub const PINA1 = 1;
pub const PINA0 = 0;

// Data Register, Port B
pub const PB7 = 7;
pub const PB6 = 6;
pub const PB5 = 5;
pub const PB4 = 4;
pub const PB3 = 3;
pub const PB2 = 2;
pub const PB1 = 1;
pub const PB0 = 0;

// Data Direction Register, Port B
pub const DDB7 = 7;
pub const DDB6 = 6;
pub const DDB5 = 5;
pub const DDB4 = 4;
pub const DDB3 = 3;
pub const DDB2 = 2;
pub const DDB1 = 1;
pub const DDB0 = 0;

// Input Pins, Port B
pub const PINB7 = 7;
pub const PINB6 = 6;
pub const PINB5 = 5;
pub const PINB4 = 4;
pub const PINB3 = 3;
pub const PINB2 = 2;
pub const PINB1 = 1;
pub const PINB0 = 0;

// Data Register, Port C
pub const PC7 = 7;
pub const PC6 = 6;
pub const PC5 = 5;
pub const PC4 = 4;
pub const PC3 = 3;
pub const PC2 = 2;
pub const PC1 = 1;
pub const PC0 = 0;

// Data Direction Register, Port C
pub const DDC7 = 7;
pub const DDC6 = 6;
pub const DDC5 = 5;
pub const DDC4 = 4;
pub const DDC3 = 3;
pub const DDC2 = 2;
pub const DDC1 = 1;
pub const DDC0 = 0;

// Input Pins, Port C
pub const PINC7 = 7;
pub const PINC6 = 6;
pub const PINC5 = 5;
pub const PINC4 = 4;
pub const PINC3 = 3;
pub const PINC2 = 2;
pub const PINC1 = 1;
pub const PINC0 = 0;

// Data Register, Port D
pub const PD7 = 7;
pub const PD6 = 6;
pub const PD5 = 5;
pub const PD4 = 4;
pub const PD3 = 3;
pub const PD2 = 2;
pub const PD1 = 1;
pub const PD0 = 0;

// Data Direction Register, Port D
pub const DDD7 = 7;
pub const DDD6 = 6;
pub const DDD5 = 5;
pub const DDD4 = 4;
pub const DDD3 = 3;
pub const DDD2 = 2;
pub const DDD1 = 1;
pub const DDD0 = 0;

// Input Pins, Port D
pub const PIND7 = 7;
pub const PIND6 = 6;
pub const PIND5 = 5;
pub const PIND4 = 4;
pub const PIND3 = 3;
pub const PIND2 = 2;
pub const PIND1 = 1;
pub const PIND0 = 0;

// SPI Status Register
pub const SPIF = 7;
pub const WCOL = 6;
pub const SPI2X = 0;

// SPI Control Register
pub const SPIE = 7;
pub const SPE = 6;
pub const DORD = 5;
pub const MSTR = 4;
pub const CPOL = 3;
pub const CPHA = 2;
pub const SPR1 = 1;
pub const SPR0 = 0;

// USART Control and Status Register A
pub const RXC = 7;
pub const TXC = 6;
pub const UDRE = 5;
pub const FE = 4;
pub const DOR = 3;
pub const PE = 2;
pub const U2X = 1;
pub const MPCM = 0;

// USART Control and Status Register B
pub const RXCIE = 7;
pub const TXCIE = 6;
pub const UDRIE = 5;
pub const RXEN = 4;
pub const TXEN = 3;
pub const UCSZ2 = 2;
pub const RXB8 = 1;
pub const TXB8 = 0;

// Analog Comparator Control and Status Register
pub const ACD = 7;
pub const ACBG = 6;
pub const ACO = 5;
pub const ACI = 4;
pub const ACIE = 3;
pub const ACIC = 2;
pub const ACIS1 = 1;
pub const ACIS0 = 0;

// ADC Multiplexer Selection Register
pub const REFS1 = 7;
pub const REFS0 = 6;
pub const ADLAR = 5;
pub const MUX4 = 4;
pub const MUX3 = 3;
pub const MUX2 = 2;
pub const MUX1 = 1;
pub const MUX0 = 0;

// ADC Control and Status Register
pub const ADEN = 7;
pub const ADSC = 6;
pub const ADATE = 5;
pub const ADIF = 4;
pub const ADIE = 3;
pub const ADPS2 = 2;
pub const ADPS1 = 1;
pub const ADPS0 = 0;

// TWI (Slave) Address Register
pub const TWGCE = 0;

// TWI Status Register
pub const TWS7 = 7;
pub const TWS6 = 6;
pub const TWS5 = 5;
pub const TWS4 = 4;
pub const TWS3 = 3;
pub const TWPS1 = 1;
pub const TWPS0 = 0;

// EEPROM Control Register
pub const EERIE = 3;
pub const EEMWE = 2;
pub const EEWE = 1;
pub const EERE = 0;

// Constants
pub const SPM_PAGESIZE = 64;
pub const RAMSTART     = 0x60;
pub const RAMEND       = 0x25F; // Last On-Chip SRAM Location
pub const XRAMEND      = RAMEND;
pub const E2END        = 0x1FF;
pub const E2PAGESIZE   = 4;
pub const FLASHEND     = 0x1FFF;
