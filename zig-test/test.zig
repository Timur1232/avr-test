const std = @import("std");

fn count_digits(num: u8) u8 {
    if (num == 0) return 1;
    var n = num;
    var count: u8 = 0;
    while (n != 0) : (n /= 10) {
        count += 1;
    }
    return count;
}

pub fn main() void {
    for (0..99) |i| {
        std.debug.print("count_digits({}): {}\n", .{i, count_digits(@intCast(i))});
    }
}
