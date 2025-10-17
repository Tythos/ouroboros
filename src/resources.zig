const std = @import("std");

/// Load a file from the filesystem and return its contents as an allocated string
/// Caller is responsible for freeing the returned memory
pub fn loadFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Error: Failed to open file '{s}': {}\n", .{ path, err });
        return err;
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    errdefer allocator.free(buffer);

    const bytes_read = try file.readAll(buffer);
    if (bytes_read != file_size) {
        std.debug.print("Error: Failed to read entire file '{s}'\n", .{path});
        return error.IncompleteRead;
    }

    return buffer;
}

/// Convenience function to load shader source code
/// Caller is responsible for freeing the returned memory
pub fn loadShaderSource(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    std.debug.print("Loading shader: {s}\n", .{path});
    return loadFile(allocator, path);
}

// Tests
test "loadFile with existing shader file" {
    const allocator = std.testing.allocator;
    const content = try loadFile(allocator, "resources/shaders/triangle.v.glsl");
    defer allocator.free(content);
    
    try std.testing.expect(content.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, content, "main") != null);
}

test "loadFile with non-existent file" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(error.FileNotFound, loadFile(allocator, "nonexistent.xyz"));
}

test "loadShaderSource with existing shader" {
    const allocator = std.testing.allocator;
    const content = try loadShaderSource(allocator, "resources/shaders/triangle.f.glsl");
    defer allocator.free(content);
    
    try std.testing.expect(content.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, content, "void main") != null);
}

test "loadShaderSource with non-existent shader" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(error.FileNotFound, loadShaderSource(allocator, "missing.f.glsl"));
}

test "loadFile memory management" {
    const allocator = std.testing.allocator;
    var content = try loadFile(allocator, "resources/shaders/triangle.v.glsl");
    
    try std.testing.expect(content.len > 0);
    allocator.free(content);
    
    // Test that we can allocate again after freeing
    content = try loadFile(allocator, "resources/shaders/triangle.f.glsl");
    try std.testing.expect(content.len > 0);
    allocator.free(content);
}

