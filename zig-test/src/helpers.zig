pub inline fn sei() void {
    asm volatile ("sei");
}

pub inline fn cli() void {
    asm volatile ("cli");
}

pub inline fn nop() void {
    asm volatile ("nop");
}

pub inline fn bit(position: c_int) u8 {
    return @as(u8, 1) << position;
}

pub inline fn is_set(reg: *volatile u8, position: c_int) bool {
    return reg.* & bit(position) != 0;
}

const F_CPU = 8000000;

pub fn delay_ms(ms: f64) void {
    var ticks: u16 = undefined;
    const tmp: f64 = ((F_CPU) / 4e3) * ms;
    if (tmp < 1.0) {
        ticks = 1;
    } else if (tmp > 65535) {
        //  ticks = requested delay in 1/10 ms
        ticks = @intFromFloat(ms * 10.0);
        while(ticks != 0) {
            // wait 1/10 ms
            delay_loop_2(((F_CPU) / 4e3) / 10);
            ticks -= 1;
        }
        return;
    } else {
        ticks = @intFromFloat(tmp);
    }
    delay_loop_2(ticks);
}

pub fn delay_loop_2(count: u16) void {
    var c = count;
    asm volatile (
        \\1: sbiw %[c], 1
        \\   brne 1b
        : [c] "+w" (c),
    );
}
