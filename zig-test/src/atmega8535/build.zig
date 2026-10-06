/// zig version: 0.16.0-dev.3013+abd131e33

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const io_translate = b.addTranslateC(.{
        .root_source_file = b.path("avr/include/avr/io.h"),
        .optimize = optimize,
        .target = target,
        .link_libc = false,
    });
    io_translate.defineCMacro(b.option([]const u8, "MMCU_MACRO", "C Macro for target MCU to pass to C preprocessor. Default: \"__AVR_ATmega8535__\"") orelse "__AVR_ATmega8535__", "");
    io_translate.defineCMacro("F_CPU", b.option([]const u8, "F_CPU", "MCU target frequency. Default: \"8000000UL\" (8 MHz)") orelse "8000000UL");
    io_translate.addIncludePath(b.path("avr/include"));
    io_translate.addIncludePath(b.path("avr/include/avr"));

    const install_translated = b.addInstallFile(io_translate.getOutput(), "avr_io_raw_translation.zig");
    b.default_step.dependOn(&install_translated.step);
    b.default_step.dependOn(&io_translate.step);

    const postprocess = b.addExecutable(.{
        .name = "postprocessing",
        .root_module = b.createModule(.{
            .root_source_file = b.path("postprocess.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        }),
        .linkage = .static,
    });

    const postprocess_run = b.addRunArtifact(postprocess);
    postprocess_run.step.dependOn(&io_translate.step);

    b.default_step.dependOn(&postprocess_run.step);
}
