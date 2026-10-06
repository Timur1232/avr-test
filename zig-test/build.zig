/// zig version: 0.16.0-dev.3013+abd131e33

const std = @import("std");

pub fn build(b: *std.Build) !void {
    const main_file_name = b.option([]const u8, "alternative_root_file_name", "Provide alternative root file name (without extention) to compile different program (e.g. for testing.). Default: main") orelse "main";
    const out_file_name = b.option([]const u8, "out_name", "Output file name (without extention). Default: program") orelse "program";

    const source_file = b.fmt("src/{s}.zig", .{main_file_name});

    const cpu = std.Target.Query {
        .cpu_arch = .avr,
        .cpu_model = .{ .explicit = &std.Target.avr.cpu.atmega8535 },
        .os_tag = .freestanding,
        .abi = .none,
    };
    const target = b.resolveTargetQuery(cpu);
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    const obj = b.addObject(.{
        .name = out_file_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(source_file),
            .target = target,
            .optimize = optimize,
            .link_libc = false,
        }),
    });

    const obj_file = obj.getEmittedBin();
    const obj_asm = obj.getEmittedAsm();

    const install_asm = b.addInstallFile(obj_asm, b.fmt("{s}.s", .{main_file_name}));
    install_asm.step.dependOn(&obj.step);
    b.default_step.dependOn(&install_asm.step);

    const elf_file_name = b.fmt("{s}.elf", .{out_file_name});
    const hex_file_name = b.fmt("{s}.hex", .{out_file_name});
    const tmp_dir = ".zig-cache/tmp";
    const elf_file = b.pathJoin(&.{tmp_dir, elf_file_name});
    const hex_file = b.pathJoin(&.{tmp_dir, hex_file_name});

    const avr_gcc = b.addSystemCommand(&.{
        "avr-gcc",
        "-mmcu=atmega8535",
        "-Os",
        "-Wl,--gc-sections",
        // "-Wl,--print-gc-sections",
        "-ffunction-sections",
        "-fdata-sections",
        "-flto",
        "-fno-builtin-isnan",
        "-fno-builtin-isinf",
        "-o", elf_file,
    });
    avr_gcc.addFileArg(obj_file);
    avr_gcc.step.dependOn(&obj.step);

    const install_elf = b.addInstallBinFile(.{ .cwd_relative = elf_file }, elf_file_name);
    install_elf.step.dependOn(&avr_gcc.step);
    b.default_step.dependOn(&install_elf.step);

    const avr_objcopy = b.addSystemCommand(&.{
        "avr-objcopy",
        "-O", "ihex",
        "-j", ".text",
        "-j", ".data",
        "-R", ".eeprom",
        elf_file,
        hex_file,
    });
    avr_objcopy.step.dependOn(&avr_gcc.step);

    const install_hex = b.addInstallBinFile(.{ .cwd_relative = hex_file }, hex_file_name);
    install_hex.step.dependOn(&avr_objcopy.step);
    b.default_step.dependOn(&install_hex.step);

    const upload_step = b.step("upload", "Upload compiled code to connected programmer.");
    const avrdude = b.addSystemCommand(&.{
        "avrdude",
        "-c", "usbasp",
        "-p", "atmega8535",
        "-P", "usb",
        "-B", "8",
        "-U", b.fmt("flash:w:{s}:i", .{hex_file}),
    });
    avrdude.step.dependOn(&install_hex.step);
    upload_step.dependOn(&avrdude.step);
}
