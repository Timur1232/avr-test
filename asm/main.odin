package main

SAMPLE_COUNT :: 64

main :: proc() {
    phase: f64
    dph := 2*math.PI / SAMPLE_COUNT
    samples: [SAMPLE_COUNT]u8
    for i in 0..<SAMPLE_COUNT {
        sine_val := (math.sin(phase) + 1) / 2
        phase += dph
        samples[i] = u8(math.ceil(sine_val*255))
    }

    fmt.println("    .byte")
    for i in 0..<8 {
        fmt.print("        ")
        for j in 0..<8 {
            fmt.print(samples[i*8 + j])
            if i*8 + j < SAMPLE_COUNT-1 {
                fmt.print(", ")
            }
        }
        fmt.println()
    }
}

import "core:fmt"
import "core:math"
