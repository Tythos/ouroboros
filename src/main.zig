const std = @import("std");
const gl = @import("gl.zig");
const Renderer = @import("renderer.zig").Renderer;
const AxesRenderer = @import("axes.zig").AxesRenderer;
const Camera = @import("camera.zig").Camera;
const OrbitController = @import("orbit_controller.zig").OrbitController;
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
        800,
        600,
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

    // Set viewport
    var window_w: i32 = 0;
    var window_h: i32 = 0;
    sdl.SDL_GetWindowSize(window, &window_w, &window_h);
    gl.glViewport(0, 0, window_w, window_h);

    // Initialize renderers
    const renderer = try Renderer.init(allocator);
    defer renderer.deinit();
    
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

    std.debug.print("OpenGL context created successfully\n", .{});
    std.debug.print("Controls:\n", .{});
    std.debug.print("  Left-click + drag: Rotate camera\n", .{});
    std.debug.print("  Mouse wheel: Zoom in/out\n", .{});
    std.debug.print("  ESC: Quit\n", .{});

    // Main event loop
    var running = true;
    const start_time = sdl.SDL_GetTicks64();
    
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

        // Calculate animation time
        const current_time = sdl.SDL_GetTicks64();
        const elapsed_ms = current_time - start_time;
        const elapsed_seconds: f32 = @as(f32, @floatFromInt(elapsed_ms)) / 1000.0;

        // Compute model matrix: rotation around all three axes for tumbling effect
        const x_rotation_speed: f32 = 1.0;   // radians per second
        const y_rotation_speed: f32 = 1.5;   // slightly faster
        const z_rotation_speed: f32 = 0.7;   // slower
        
        const angle_x: f32 = elapsed_seconds * x_rotation_speed;
        const angle_y: f32 = elapsed_seconds * y_rotation_speed;
        const angle_z: f32 = elapsed_seconds * z_rotation_speed;
        
        const x_axis = CameraModule.Vec3.new(1.0, 0.0, 0.0);
        const y_axis = CameraModule.Vec3.new(0.0, 1.0, 0.0);
        const z_axis = CameraModule.Vec3.new(0.0, 0.0, 1.0);
        
        const rotation_x = CameraModule.Mat4.createAngleAxis(x_axis, angle_x);
        const rotation_y = CameraModule.Mat4.createAngleAxis(y_axis, angle_y);
        const rotation_z = CameraModule.Mat4.createAngleAxis(z_axis, angle_z);
        
        // Combine rotations: apply Z, then Y, then X (order matters!)
        const model_matrix = rotation_x.mul(rotation_y.mul(rotation_z));

        // Render the scene
        renderer.render(model_matrix, &camera);
        
        // Render coordinate axes for reference
        axes_renderer.render(&camera);

        // Swap buffers
        sdl.SDL_GL_SwapWindow(window);
    }

    std.debug.print("Application exited successfully\n", .{});
}
