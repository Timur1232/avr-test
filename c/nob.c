#include <string.h>

#define NOB_IMPLEMENTATION
#include "nob.h"

#define BUILD_DIR "build/"

bool compile_program(Cmd *cmd, char *main_filename) {
    if (!needs_rebuild1(temp_sprintf(BUILD_DIR "%s.elf", main_filename), temp_sprintf("%s.c", main_filename))) return true;
    cmd_append(cmd, "avr-gcc");
    cmd_append(cmd, "-Wall", "-Wextra");
    cmd_append(cmd, "-g");
    cmd_append(cmd, "-Os");
    cmd_append(cmd, "-mmcu=atmega8535");
    cmd_append(cmd, "-DF_CPU=8000000UL");
    cmd_append(cmd, "-o", temp_sprintf(BUILD_DIR "%s.elf", main_filename));
    cmd_append(cmd, temp_sprintf("%s.c", main_filename));
    return cmd_run(cmd);
}

bool link_program(Cmd *cmd, char *main_filename) {
    if (!compile_program(cmd, main_filename)) {
        nob_log(NOB_ERROR, "Unable to compile program.");
        return false;
    }
    if (!needs_rebuild1(temp_sprintf(BUILD_DIR "%s.hex", main_filename), temp_sprintf(BUILD_DIR "%s.elf", main_filename))) return true;
    cmd_append(cmd, "avr-objcopy");
    cmd_append(cmd, "-j", ".text");
    cmd_append(cmd, "-j", ".data");
    cmd_append(cmd, "-O", "ihex");
    cmd_append(cmd, temp_sprintf(BUILD_DIR "%s.elf", main_filename));
    cmd_append(cmd, temp_sprintf(BUILD_DIR "%s.hex", main_filename));
    return cmd_run(cmd);
}

bool upload_program(Cmd *cmd, char *main_filename) {
    if (!link_program(cmd, main_filename)) {
        nob_log(NOB_ERROR, "Unable to link program.");
        return false;
    }
    cmd_append(cmd, "avrdude");
    cmd_append(cmd, "-p", "atmega8535");
    cmd_append(cmd, "-c", "usbasp");
    cmd_append(cmd, "-P", "usb");
    cmd_append(cmd, "-B", "8");
    cmd_append(cmd, "-U", temp_sprintf("flash:w:"BUILD_DIR"%s.hex:i", main_filename));
    return cmd_run(cmd);
}

void write_usage(char *program_name) {
    fprintf(stderr, "USAGE: %s <command> <program_name>\n\n    <command> - compile, upload\n    <program_name> - Name of a main program file without extention (e.g if main program file is `foo.c`, then you pass `foo`)\n\nCOMMANDS:\n    compile - just compile and link program to hex format. Will write it to build/<program_name>.hex.\n    upload - compile, link and upload program to connected MCU.\n\nFLAGS:\n    -h - print this messege.\n", program_name);
}

int main(int argc, char **argv) {
    NOB_GO_REBUILD_URSELF(argc, argv);
    char *program_name = shift(argv, argc);

    if (argc < 2) {
        write_usage(program_name);
        return -1;
    }

    char *command = shift(argv, argc);

    if (strcmp(command, "-h") == 0) {
        write_usage(program_name);
        return -1;
    }

    char *main_filename = shift(argv, argc);

    if (!mkdir_if_not_exists("build")) {
        nob_log(NOB_ERROR, "Unable to create build directory.");
        return -1;
    }

    Cmd cmd = {0};
    if (strcmp(command, "compile") == 0) {
        if (!link_program(&cmd, main_filename)) {
            nob_log(NOB_ERROR, "Unable to compile or link program.");
            return -1;
        }
        nob_log(NOB_INFO, "Program compiled.");
    } else if (strcmp(command, "upload") == 0) {
        if (!upload_program(&cmd, main_filename)) {
            nob_log(NOB_ERROR, "Unable to upload program.");
            return -1;
        }
        nob_log(NOB_INFO, "Program compiled and uploaded to MCU.");
    } else {
        write_usage(program_name);
        return -1;
    }
    return 0;
}
