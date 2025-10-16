const std = @import("std");
const builtin = @import("builtin");
const SDL = @import("build/SDL.zig");

pub fn build(b: *std.Build) void {
    // Verify we're using Zig 0.12.x
    const required_major = 0;
    const required_minor = 12;
    const required_patch = 1;
    if (builtin.zig_version.major != required_major or builtin.zig_version.minor != required_minor or builtin.zig_version.patch != required_patch) {
        @panic("This project requires Zig 0.12.1");
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ouroboros",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Build and link SDL2
    SDL.linkSDL2(b, exe, target);
    
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
                 
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });                                                                                                                                                         

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
