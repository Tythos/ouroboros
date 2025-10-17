const std = @import("std");
const gl = @import("gl.zig");
const Renderer = @import("renderer.zig").Renderer;
const Camera = @import("camera.zig").Camera;
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

    // Initialize renderer
    const renderer = try Renderer.init(allocator);
    defer renderer.deinit();

    // Initialize camera at (1, 2, 3) looking at origin
    var cam = Camera.default();
    
    // Set correct aspect ratio based on actual window dimensions
    cam.setAspectRatio(@as(f32, @floatFromInt(window_w)), @as(f32, @floatFromInt(window_h)));
    
    std.debug.print("OpenGL context created successfully\n", .{});
    std.debug.print("Press ESC or close the window to quit\n", .{});

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
        }

        // Calculate rotation angle based on time
        const current_time = sdl.SDL_GetTicks64();
        const elapsed_ms = current_time - start_time;
        const elapsed_seconds: f32 = @as(f32, @floatFromInt(elapsed_ms)) / 1000.0;
        const rotation_speed: f32 = 1.0; // radians per second
        const angle: f32 = elapsed_seconds * rotation_speed;

        // Render the scene with camera
        renderer.render(angle, cam);

        // Swap buffers
        sdl.SDL_GL_SwapWindow(window);
    }

    std.debug.print("Application exited successfully\n", .{});
}
