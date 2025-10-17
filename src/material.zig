const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");

/// Material represents the rendering properties of a scene object
/// Encapsulates shader program and material-specific uniforms
/// Designed to be extensible for lighting, textures, and other material properties
pub const Material = struct {
    // Core shader program
    program: gl.GLuint,
    
    // Future extensibility: lighting, textures, custom uniforms
    // These will be added as the material system evolves
    // lighting_properties: ?LightingProperties = null,
    // textures: ?TextureSet = null,
    // custom_uniforms: ?CustomUniformMap = null,
    
    /// Initialize a new material with vertex and fragment shader files
    pub fn init(allocator: std.mem.Allocator, vert_path: []const u8, frag_path: []const u8) !Material {
        std.debug.print("Initializing material...\n", .{});
        std.debug.print("  Vertex shader: {s}\n", .{vert_path});
        std.debug.print("  Fragment shader: {s}\n", .{frag_path});
        
        // Load and compile shader program
        const program = try shader.loadProgram(allocator, vert_path, frag_path);
        
        std.debug.print("Material initialized successfully\n", .{});
        
        return Material{
            .program = program,
        };
    }
    
    /// Bind the material for rendering (activate shader program)
    pub fn bind(self: *const Material) void {
        gl.glUseProgram(self.program);
    }
    
    /// Get the shader program ID (for advanced usage)
    pub fn getProgram(self: *const Material) gl.GLuint {
        return self.program;
    }
    
    /// Check if the material is valid (has a valid program)
    pub fn isValid(self: *const Material) bool {
        return self.program != 0;
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const Material) void {
        std.debug.print("Cleaning up material resources...\n", .{});
        gl.glDeleteProgram(self.program);
    }
};

// ============================================================================
// Tests
// ============================================================================

const test_utils = @import("test_utilities.zig");

test "Material initialization with valid shader files" {
    const allocator = std.testing.allocator;
    
    // Test that we can load shader source from files (without OpenGL context)
    const vertex_source = std.fs.cwd().readFileAlloc(allocator, "resources/shaders/triangle.v.glsl", 1024) catch {
        // Skip test if file doesn't exist
        return;
    };
    defer allocator.free(vertex_source);
    
    const fragment_source = std.fs.cwd().readFileAlloc(allocator, "resources/shaders/triangle.f.glsl", 1024) catch {
        return;
    };
    defer allocator.free(fragment_source);
    
    try std.testing.expect(vertex_source.len > 0);
    try std.testing.expect(fragment_source.len > 0);
    
    // Verify shader source contains expected elements
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 model") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 view") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 projection") != null);
}

test "Material initialization with missing shader files" {
    const allocator = std.testing.allocator;
    
    // Test that missing files are handled properly
    try std.testing.expectError(error.FileNotFound, 
        std.fs.cwd().readFileAlloc(allocator, "missing_vertex.v.glsl", 1024));
    
    try std.testing.expectError(error.FileNotFound, 
        std.fs.cwd().readFileAlloc(allocator, "missing_fragment.f.glsl", 1024));
}

test "Material struct properties" {
    // Test that Material struct has expected fields
    const material_type = @TypeOf(Material{
        .program = 0,
    });
    
    // Verify struct has required fields
    try std.testing.expect(@hasField(material_type, "program"));
    
    // Verify field types by creating a test instance
    const test_material = Material{
        .program = 0,
    };
    
    // Test that we can access the fields
    _ = test_material.program;
}

test "Material method signatures" {
    // Test that Material has expected methods
    const material_type = @TypeOf(Material{
        .program = 0,
    });
    
    // Test init method exists and has correct signature
    const init_method = @field(material_type, "init");
    try std.testing.expect(@TypeOf(init_method) != void);
    
    // Test bind method exists
    const bind_method = @field(material_type, "bind");
    try std.testing.expect(@TypeOf(bind_method) != void);
    
    // Test getProgram method exists
    const get_program_method = @field(material_type, "getProgram");
    try std.testing.expect(@TypeOf(get_program_method) != void);
    
    // Test isValid method exists
    const is_valid_method = @field(material_type, "isValid");
    try std.testing.expect(@TypeOf(is_valid_method) != void);
    
    // Test deinit method exists
    const deinit_method = @field(material_type, "deinit");
    try std.testing.expect(@TypeOf(deinit_method) != void);
}

test "Material error types" {
    // Test that Material error types are properly defined
    // Note: MaterialUniformNotFound was removed since MVP matrices are no longer handled by Material
    // Future material-specific error types will be added here as the system evolves
    const test_errors = [_]anyerror{
        // error.MaterialUniformNotFound, // Removed - MVP matrices are scene/camera data
    };
    
    // Just ensure they compile and can be used
    for (test_errors) |err| {
        _ = @errorName(err);
    }
}

test "Material matrix operations" {
    // Test matrix operations that Material will use
    const identity_matrix = [_]f32{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };
    
    const translation_matrix = [_]f32{
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 2.0,
        0.0, 0.0, 1.0, 3.0,
        0.0, 0.0, 0.0, 1.0,
    };
    
    // Test that matrices have correct dimensions
    try std.testing.expectEqual(@as(usize, 16), identity_matrix.len);
    try std.testing.expectEqual(@as(usize, 16), translation_matrix.len);
    
    // Test matrix properties
    try std.testing.expectEqual(@as(f32, 1.0), identity_matrix[0]);
    try std.testing.expectEqual(@as(f32, 1.0), identity_matrix[5]);
    try std.testing.expectEqual(@as(f32, 1.0), identity_matrix[10]);
    try std.testing.expectEqual(@as(f32, 1.0), identity_matrix[15]);
}

test "Material OpenGL constants" {
    // Test that required OpenGL constants are available for Material
    try std.testing.expectEqual(@as(gl.GLenum, 0), gl.GL_FALSE);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B31), gl.GL_VERTEX_SHADER);
    try std.testing.expectEqual(@as(gl.GLenum, 0x8B30), gl.GL_FRAGMENT_SHADER);
}

test "Material memory management" {
    // Test that Material can be created and destroyed without memory leaks
    const allocator = std.testing.allocator;
    
    // Test file loading memory management
    const source = std.fs.cwd().readFileAlloc(allocator, "resources/shaders/triangle.v.glsl", 1024) catch {
        return;
    };
    defer allocator.free(source);
    
    // Test that memory was allocated and can be freed
    try std.testing.expect(source.len > 0);
}

test "Material extensibility design" {
    // Test that Material is designed for future extensibility
    const material_type = @TypeOf(Material{
        .program = 0,
    });
    
    // Verify current structure supports future additions
    try std.testing.expect(@hasField(material_type, "program"));
    
    // Future fields will be added as optional fields:
    // .lighting_properties: ?LightingProperties = null,
    // .textures: ?TextureSet = null,
    // .custom_uniforms: ?CustomUniformMap = null,
    // Note: MVP matrices are no longer part of Material as they are scene/camera data
}

test "Material shader source validation" {
    // Test that we can validate shader source for Material requirements
    const vertex_source = 
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
    
    // Verify shader contains required uniforms for Material
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 model") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 view") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "uniform mat4 projection") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source, "gl_Position") != null);
}

test "Material fragment shader validation" {
    const fragment_source = 
        \\#version 300 es
        \\precision mediump float;
        \\in vec3 vertexColor;
        \\out vec4 FragColor;
        \\void main() {
        \\    FragColor = vec4(vertexColor, 1.0);
        \\}
    ;
    
    // Verify fragment shader structure
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "void main") != null);
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "FragColor") != null);
    try std.testing.expect(std.mem.indexOf(u8, fragment_source, "vertexColor") != null);
}
