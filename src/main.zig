const std = @import("std");
const zlm = @import("zlm").as(f32);
const gl = @import("gl.zig");
const renderer_utils = @import("renderer.zig");
const AxesRenderer = @import("axes.zig").AxesRenderer;
const Camera = @import("camera.zig").Camera;
const OrbitController = @import("orbit_controller.zig").OrbitController;
const SceneGraphNode = @import("scene_graph_node.zig").SceneGraphNode;
const Geometry = @import("geometry.zig").Geometry;
const Material = @import("material.zig").Material;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.debug.print("SDL_Init Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    // Set OpenGL ES 3.0 attributes (system has EGL with GLES support)
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 0);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_ES);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);

    // Create window with OpenGL flag
    const window = sdl.SDL_CreateWindow(
        "Ouroboros - OpenGL Triangle",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        1600,
        900,
        sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_SHOWN,
    ) orelse {
        std.debug.print("SDL_CreateWindow Error: {s}\n", .{sdl.SDL_GetError()});
        return error.WindowCreationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    // Create OpenGL context
    const gl_context = sdl.SDL_GL_CreateContext(window);
    if (gl_context == null) {
        std.debug.print("SDL_GL_CreateContext Error: {s}\n", .{sdl.SDL_GetError()});
        return error.GLContextCreationFailed;
    }
    defer sdl.SDL_GL_DeleteContext(gl_context);

    // Enable VSync
    _ = sdl.SDL_GL_SetSwapInterval(1);

    // Load OpenGL functions
    gl.loadFunctions();

    // Enable depth testing for 3D rendering
    gl.glEnable(gl.GL_DEPTH_TEST);

    // Set viewport
    var window_w: i32 = 0;
    var window_h: i32 = 0;
    sdl.SDL_GetWindowSize(window, &window_w, &window_h);
    gl.glViewport(0, 0, window_w, window_h);

    // Setup common rendering state (depth testing, etc.)
    renderer_utils.setupRenderState();

    // Initialize axes renderer (still using old approach for debugging)
    const axes_renderer = try AxesRenderer.init(allocator);
    defer axes_renderer.deinit();

    // Create camera on +X axis looking back at origin (Z-up coordinate system)
    const aspect: f32 = @as(f32, @floatFromInt(window_w)) / @as(f32, @floatFromInt(window_h));
    const CameraModule = @import("camera.zig");
    var camera = Camera.initLookAt(
        CameraModule.Vec3.new(5.0, 0.0, 0.0),     // Position on +X axis, far enough to see triangle
        CameraModule.Vec3.new(0.0, 0.0, 0.0),     // Looking at origin
        CameraModule.Vec3.new(0.0, 0.0, 1.0),     // Up is +Z (as god intended)
        std.math.degreesToRadians(60.0),          // FOV
        aspect,
        1e-1,                                     // Near plane
        1e+3,                                     // Far plane
    );

    // Initialize orbit controller from current camera position
    var orbit_controller = OrbitController.initFromCamera(&camera);

    // Create cube geometry (shared between parent and child)
    var cube_geometry = try Geometry.initCube();
    defer cube_geometry.deinit();
    
    // Create materials for the cubes (same shader, but different instances)
    var parent_material = try Material.init(allocator, "resources/shaders/triangle.v.glsl", "resources/shaders/triangle.f.glsl");
    defer parent_material.deinit();
    
    var child_material = try Material.init(allocator, "resources/shaders/triangle.v.glsl", "resources/shaders/triangle.f.glsl");
    defer child_material.deinit();
    
    // Create parent cube (larger, slower rotation)
    var parent_cube = try SceneGraphNode.init(allocator, &cube_geometry, &parent_material);
    defer parent_cube.deinit();
    
    // Set parent transform (translate and scale)
    const parent_translation = zlm.Mat4.createTranslation(zlm.Vec3.new(0.0, 0.0, 0.0)); // At origin
    const parent_scale = zlm.Mat4.createScale(1.0, 1.0, 1.0); // Normal size
    parent_cube.setTransform(parent_scale.mul(parent_translation));
    parent_cube.x_rotation_speed = 0.5; // Slow rotation
    parent_cube.y_rotation_speed = 0.3;
    parent_cube.z_rotation_speed = 0.2;
    
    // Create child cube (smaller, faster rotation, offset from parent)
    var child_cube = try SceneGraphNode.init(allocator, &cube_geometry, &child_material);
    defer child_cube.deinit();
    
    // Set child transform (offset from parent)
    const child_translation = zlm.Mat4.createTranslation(zlm.Vec3.new(3.0, 0.0, 0.0)); // 3 units to the right
    const child_scale = zlm.Mat4.createScale(0.5, 0.5, 0.5); // 50% smaller
    child_cube.setTransform(child_scale.mul(child_translation));
    child_cube.x_rotation_speed = 1.0; // Faster rotation
    child_cube.y_rotation_speed = 1.5;
    child_cube.z_rotation_speed = 0.8;
    
    // Create parent-child relationship
    try parent_cube.addChild(&child_cube);
    
    std.debug.print("Created parent-child cube scene:\n", .{});
    std.debug.print("  Parent: normal size, slow rotation at origin\n", .{});
    std.debug.print("  Child: smaller, faster rotation, offset from parent\n", .{});
    

    std.debug.print("OpenGL context created successfully\n", .{});
    std.debug.print("Controls:\n", .{});
    std.debug.print("  Left-click + drag: Rotate camera\n", .{});
    std.debug.print("  Mouse wheel: Zoom in/out\n", .{});
    std.debug.print("  ESC: Quit\n", .{});

    // Main event loop
    var running = true;
    var last_time = sdl.SDL_GetTicks64();
    
    while (running) {
        // Handle events
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => running = false,
                sdl.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == sdl.SDLK_ESCAPE) {
                        running = false;
                    }
                },
                else => {},
            }
            
            // Pass event to orbit controller
            orbit_controller.handleEvent(&event);
        }

        // Update camera from orbit controller
        orbit_controller.updateCamera(&camera);

        // Calculate delta time
        const current_time = sdl.SDL_GetTicks64();
        const delta_ms = current_time - last_time;
        const delta_time: f32 = @as(f32, @floatFromInt(delta_ms)) / 1000.0;
        last_time = current_time;
        
        // Update scene graph node animation (recursive - updates parent and all children)
        parent_cube.update(delta_time);

        // Clear the screen (dark grey background)
        renderer_utils.clearScreen(0.1, 0.1, 0.1, 1.0);

        // Render the scene (recursive - renders parent and all children)
        parent_cube.render(&camera);
        
        // Render coordinate axes for reference
        axes_renderer.render(&camera);

        // Swap buffers
        sdl.SDL_GL_SwapWindow(window);
    }

    std.debug.print("Application exited successfully\n", .{});
}
