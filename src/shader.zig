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
