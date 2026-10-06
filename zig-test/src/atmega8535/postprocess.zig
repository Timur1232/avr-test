const std = @import("std");
const cwd = std.Io.Dir.cwd();

const mmio_byte =
    \\pub fn _MMIO_BYTE(addr: comptime_int) *volatile u8 {
    \\    return @ptrFromInt(addr);
    \\}
;
const mmio_word =
    \\pub fn _MMIO_WORD(addr: comptime_int) *volatile u16 {
    \\    return @ptrFromInt(addr);
    \\}
;
const mmio_dword =
    \\pub fn _MMIO_DWORD(addr: comptime_int) *volatile u32 {
    \\    return @ptrFromInt(addr);
    \\}
;


pub fn main(init: std.process.Init) !void {
    const arena_allocator = init.arena.allocator();

    const translated = try cwd.readFileAlloc(init.io, "./zig-out/avr_io_raw_translation.zig", arena_allocator, .unlimited);
    var fixed = try std.ArrayList(u8).initCapacity(arena_allocator, translated.len);

    var iter = std.mem.splitScalar(u8, translated, '\n');
    while (iter.next()) |line| {
        if (std.mem.indexOf(u8, line, "const _MMIO_BYTE")) |_| {
            try fixed.appendSlice(arena_allocator, mmio_byte);
        } else if (std.mem.indexOf(u8, line, "const _MMIO_WORD")) |_| {
            try fixed.appendSlice(arena_allocator, mmio_word);
        } else if (std.mem.indexOf(u8, line, "const _MMIO_DWORD")) |_| {
            try fixed.appendSlice(arena_allocator, mmio_dword);
        } else {
            try fixed.appendSlice(arena_allocator, line);
        }
        try fixed.append(arena_allocator, '\n');
    }

    try cwd.writeFile(init.io, .{
        .data = fixed.items,
        .sub_path = "./zig-out/avr_io.zig",
        .flags = .{ .truncate = true },
    });
}
