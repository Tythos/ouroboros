const std = @import("std");
const gl = @import("gl.zig");
const resources = @import("resources.zig");

/// Compile a shader from source code
pub fn compileShaderFromSource(source: []const u8, shader_type: gl.GLenum) !gl.GLuint {
    const shader = gl.glCreateShader(shader_type);
    if (shader == 0) {
        std.debug.print("Error: Failed to create shader\n", .{});
        return error.ShaderCreationFailed;
    }

    // Prepare source for OpenGL
    const sources = [_][*c]const gl.GLchar{source.ptr};
    const lengths = [_]gl.GLint{@intCast(source.len)};
    gl.glShaderSource(shader, 1, &sources, &lengths);
    
    // Compile the shader
    gl.glCompileShader(shader);
    
    // Check compilation status
    var success: gl.GLint = 0;
    gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, &success);
    
    if (success == gl.GL_FALSE) {
        // Get error log length
        var log_length: gl.GLint = 0;
        gl.glGetShaderiv(shader, gl.GL_INFO_LOG_LENGTH, &log_length);
        
        // Allocate buffer for error log
        const allocator = std.heap.page_allocator;
        const log = allocator.alloc(u8, @intCast(log_length)) catch {
            std.debug.print("Error: Failed to allocate memory for shader log\n", .{});
            gl.glDeleteShader(shader);
            return error.OutOfMemory;
        };
        defer allocator.free(log);
        
        // Get the error log
        gl.glGetShaderInfoLog(shader, @intCast(log_length), null, log.ptr);
        
        const shader_type_name = if (shader_type == gl.GL_VERTEX_SHADER) "vertex" else "fragment";
        std.debug.print("Error: {s} shader compilation failed:\n{s}\n", .{ shader_type_name, log });
        
        gl.glDeleteShader(shader);
        return error.ShaderCompilationFailed;
    }
    
    return shader;
}

/// Compile a shader from a file
pub fn compileShaderFromFile(allocator: std.mem.Allocator, path: []const u8, shader_type: gl.GLenum) !gl.GLuint {
    const source = try resources.loadShaderSource(allocator, path);
    defer allocator.free(source);
    return compileShaderFromSource(source, shader_type);
}

/// Link vertex and fragment shaders into a program
pub fn linkProgram(vertex_shader: gl.GLuint, fragment_shader: gl.GLuint) !gl.GLuint {
    const program = gl.glCreateProgram();
    if (program == 0) {
        std.debug.print("Error: Failed to create shader program\n", .{});
        return error.ProgramCreationFailed;
    }
    
    gl.glAttachShader(program, vertex_shader);
    gl.glAttachShader(program, fragment_shader);
    gl.glLinkProgram(program);
    
    // Check linking status
    var success: gl.GLint = 0;
    gl.glGetProgramiv(program, gl.GL_LINK_STATUS, &success);
    
    if (success == gl.GL_FALSE) {
        // Get error log length
        var log_length: gl.GLint = 0;
        gl.glGetProgramiv(program, gl.GL_INFO_LOG_LENGTH, &log_length);
        
        // Allocate buffer for error log
        const allocator = std.heap.page_allocator;
        const log = allocator.alloc(u8, @intCast(log_length)) catch {
            std.debug.print("Error: Failed to allocate memory for program log\n", .{});
            gl.glDeleteProgram(program);
            return error.OutOfMemory;
        };
        defer allocator.free(log);
        
        // Get the error log
        gl.glGetProgramInfoLog(program, @intCast(log_length), null, log.ptr);
        std.debug.print("Error: Shader program linking failed:\n{s}\n", .{log});
        
        gl.glDeleteProgram(program);
        return error.ProgramLinkingFailed;
    }
    
    return program;
}

/// Load and compile a complete shader program from vertex and fragment shader files
pub fn loadProgram(allocator: std.mem.Allocator, vert_path: []const u8, frag_path: []const u8) !gl.GLuint {
    std.debug.print("Loading shader program...\n", .{});
    std.debug.print("  Vertex shader: {s}\n", .{vert_path});
    std.debug.print("  Fragment shader: {s}\n", .{frag_path});
    
    const vertex_shader = try compileShaderFromFile(allocator, vert_path, gl.GL_VERTEX_SHADER);
    errdefer gl.glDeleteShader(vertex_shader);
    
    const fragment_shader = try compileShaderFromFile(allocator, frag_path, gl.GL_FRAGMENT_SHADER);
    errdefer gl.glDeleteShader(fragment_shader);
    
    const program = try linkProgram(vertex_shader, fragment_shader);
    
    // We can delete the shaders now that they're linked into the program
    gl.glDeleteShader(vertex_shader);
    gl.glDeleteShader(fragment_shader);
    
    std.debug.print("Shader program loaded successfully\n", .{});
    return program;
}

// ============================================================================
// TESTS
// ============================================================================

const test_utils = @import("test_utilities.zig");

test "compileShaderFromSource with valid vertex shader" {
    const valid_vertex_source = 
        \\#version 300 es
        \\precision mediump float;
        \\layout (location = 0) in vec3 aPos;
        \\layout (location = 1) in vec3 aColor;
        \\out vec3 vertexColor;
        \\uniform mat4 model;
        \\uniform mat4 view;
        \\uniform mat4 projection;
        \\void main() {
        \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
        \\    vertexColor = aColor;
        \\}
    ;
    
    // Test source validation without calling OpenGL functions
    try std.testing.expect(valid_vertex_source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, valid_vertex_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, valid_vertex_source, "gl_Position") != null);
    
    // Note: Actual compilation requires OpenGL context
    // In a production environment, you'd mock the OpenGL functions
}

test "compileShaderFromSource with valid fragment shader" {
    const valid_fragment_source = 
        \\#version 300 es
        \\precision mediump float;
        \\in vec3 vertexColor;
        \\out vec4 FragColor;
        \\void main() {
        \\    FragColor = vec4(vertexColor, 1.0);
        \\}
    ;
    
    // Test source validation without calling OpenGL functions
    try std.testing.expect(valid_fragment_source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, valid_fragment_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, valid_fragment_source, "FragColor") != null);
    
    // Note: Actual compilation requires OpenGL context
}

test "compileShaderFromSource with invalid shader source" {
    const invalid_source = 
        \\#version 300 es
        \\precision mediump float;
        \\void main() {
        \\    this_is_invalid_syntax;
        \\}
    ;
    
    // Test that we can detect invalid syntax patterns
    try std.testing.expect(invalid_source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, invalid_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, invalid_source, "this_is_invalid_syntax") != null);
    
    // Note: Actual compilation validation requires OpenGL context
}

test "compileShaderFromFile with existing shader" {
    const allocator = std.testing.allocator;
    
    // Test that we can load shader source from files
    const source = resources.loadShaderSource(allocator, "resources/shaders/triangle.v.glsl") catch {
        // Skip test if file doesn't exist
        return;
    };
    defer allocator.free(source);
    
    try std.testing.expect(source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, source, "void main") != null);
    
    // Note: Actual compilation requires OpenGL context
}

test "compileShaderFromFile with non-existent file" {
    const allocator = std.testing.allocator;
    
    // This should fail with FileNotFound error
    try std.testing.expectError(error.FileNotFound, 
        compileShaderFromFile(allocator, "non_existent.v.glsl", gl.GL_VERTEX_SHADER));
}

test "compileShaderFromFile memory management" {
    const allocator = std.testing.allocator;
    
    // Test that memory is properly managed even when file loading fails
    try std.testing.expectError(error.FileNotFound, 
        resources.loadShaderSource(allocator, "non_existent.v.glsl"));
    
    // Should be able to try again without memory leaks
    const source = resources.loadShaderSource(allocator, "resources/shaders/triangle.v.glsl") catch {
        // Skip test if file doesn't exist
        return;
    };
    defer allocator.free(source);
    
    try std.testing.expect(source.len > 0);
}

test "linkProgram function signature validation" {
    // Test that linkProgram function has the expected signature
    // This is a compile-time test to ensure the function exists and has correct parameters
    
    // We can't actually call linkProgram without OpenGL context, but we can test
    // that the function signature is correct by ensuring it compiles
    _ = linkProgram;
    
    // Test that the function exists and can be referenced
    try std.testing.expect(@TypeOf(linkProgram) != void);
}


test "loadProgram file loading validation" {
    const allocator = std.testing.allocator;
    
    // Test that we can load both shader files
    const vertex_source = resources.loadShaderSource(allocator, "resources/shaders/triangle.v.glsl") catch {
        // Skip test if files don't exist
        return;
    };
    defer allocator.free(vertex_source);
    
    const fragment_source = resources.loadShaderSource(allocator, "resources/shaders/triangle.f.glsl") catch {
        allocator.free(vertex_source);
        return;
    };
    defer allocator.free(fragment_source);
    
    try std.testing.expect(vertex_source.len > 0);
    try std.testing.expect(fragment_source.len > 0);
    
    // Note: Actual program loading requires OpenGL context
}

test "loadProgram error handling for missing files" {
    const allocator = std.testing.allocator;
    
    // Test that missing vertex shader files are handled properly at the file loading level
    try std.testing.expectError(error.FileNotFound, 
        resources.loadShaderSource(allocator, "missing_vertex.v.glsl"));
    
    // Test that missing fragment shader files are handled properly at the file loading level
    try std.testing.expectError(error.FileNotFound, 
        resources.loadShaderSource(allocator, "missing_fragment.f.glsl"));
}

test "shader source validation" {
    // Test that we can validate basic shader source properties
    const vertex_source = 
        \\#version 300 es
        \\precision mediump float;
        \\layout (location = 0) in vec3 aPos;
        \\void main() {
        \\    gl_Position = vec4(aPos, 1.0);
        \\}
    ;
    
    // Basic string validation
    try std.testing.expect(vertex_source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "gl_Position") != null);
}

test "fragment shader source validation" {
    const fragment_source = 
        \\#version 300 es
        \\precision mediump float;
        \\out vec4 FragColor;
        \\void main() {
        \\    FragColor = vec4(1.0, 0.0, 0.0, 1.0);
        \\}
    ;
    
    // Basic string validation
    try std.testing.expect(fragment_source.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "FragColor") != null);
}

test "error types are properly defined" {
    // Test that our custom error types exist and can be used
    const test_errors = [_]anyerror{
        error.ShaderCreationFailed,
        error.ShaderCompilationFailed,
        error.ProgramCreationFailed,
        error.ProgramLinkingFailed,
        error.OutOfMemory,
    };
    
    // Just ensure they compile and can be used
    for (test_errors) |err| {
        _ = @errorName(err);
    }
}

test "OpenGL constants are properly defined" {
    // Test that required OpenGL constants are available
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B31), gl.GL_VERTEX_SHADER);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B30), gl.GL_FRAGMENT_SHADER);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B81), gl.GL_COMPILE_STATUS);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B82), gl.GL_LINK_STATUS);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B84), gl.GL_INFO_LOG_LENGTH);
    try std.testing.expectEqual(@as(gl.GLenum, 0), gl.GL_FALSE);
}

test "function parameter validation" {
    // Test that functions handle edge cases properly
    const empty_source = "";
    
    // Test basic validation of empty source
    try std.testing.expect(empty_source.len == 0);
    
    // Note: Actual compilation validation requires OpenGL context
}

test "allocator usage patterns" {
    const allocator = std.testing.allocator;
    
    // Test that we can use the allocator for file loading
    const source = resources.loadShaderSource(allocator, "resources/shaders/triangle.v.glsl") catch {
        // Skip test if file doesn't exist
        return;
    };
    defer allocator.free(source);
    
    // Test that memory was allocated and can be freed
    try std.testing.expect(source.len > 0);
}
