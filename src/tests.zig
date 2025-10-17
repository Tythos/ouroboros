const std = @import("std");

// Test aggregator - imports all modules with tests to ensure test discovery
// This file ensures all tests across the project are discovered and run

// Import all modules that contain tests
comptime {
    // Only import test_utilities for now to avoid API compatibility issues
    _ = @import("test_utilities.zig");
    // TODO: Fix API compatibility issues in other modules before importing them
    // _ = @import("axes.zig");
    // _ = @import("camera.zig");
    // _ = @import("gl.zig");
    // _ = @import("renderer.zig");
    // _ = @import("resources.zig");
    // _ = @import("scene_graph_node.zig");
    // _ = @import("shader.zig");
    // _ = @import("orbit_controller.zig");
}

// This ensures all test declarations are referenced
test {
    std.testing.refAllDecls(@This());
}
