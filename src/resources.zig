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

