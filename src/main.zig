const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

fn render(renderer: *sdl.SDL_Renderer, window: *sdl.SDL_Window, angle: f32) void {
    // Clear screen (dark blue)
    _ = sdl.SDL_SetRenderDrawColor(renderer, 30, 30, 60, 255);
    _ = sdl.SDL_RenderClear(renderer);

    // Get window dimensions
    var window_w: i32 = 0;
    var window_h: i32 = 0;
    sdl.SDL_GetWindowSize(window, &window_w, &window_h);
    
    const center_x: f32 = @as(f32, @floatFromInt(window_w)) / 2.0;
    const center_y: f32 = @as(f32, @floatFromInt(window_h)) / 2.0;
    const square_size: f32 = 100.0;
    const half_size: f32 = square_size / 2.0;
    
    // Calculate rotated corners of the square
    const cos_angle = @cos(angle);
    const sin_angle = @sin(angle);
    
    // Define the four corners relative to center (before rotation)
    const corners = [4][2]f32{
        .{ -half_size, -half_size }, // Top-left
        .{ half_size, -half_size },  // Top-right
        .{ half_size, half_size },   // Bottom-right
        .{ -half_size, half_size },  // Bottom-left
    };
    
    // Rotate and translate corners
    var rotated_corners: [4]sdl.SDL_Point = undefined;
    for (corners, 0..) |corner, i| {
        const x = corner[0];
        const y = corner[1];
        const rotated_x = x * cos_angle - y * sin_angle;
        const rotated_y = x * sin_angle + y * cos_angle;
        rotated_corners[i] = sdl.SDL_Point{
            .x = @as(i32, @intFromFloat(center_x + rotated_x)),
            .y = @as(i32, @intFromFloat(center_y + rotated_y)),
        };
    }
    
    // Draw filled polygon (approximation with lines)
    // First fill the square by drawing horizontal scanlines
    _ = sdl.SDL_SetRenderDrawColor(renderer, 200, 180, 150, 255);
    
    // For simplicity, draw the outline multiple times with slight offsets to simulate fill
    // This is a simple approach; a proper filled polygon would require scanline conversion
    var offset: i32 = -50;
    while (offset <= 50) : (offset += 1) {
        const scale = 1.0 - (@as(f32, @floatFromInt(@abs(offset))) / 50.0) * 0.3;
        var filled_corners: [4]sdl.SDL_Point = undefined;
        for (corners, 0..) |corner, i| {
            const x = corner[0] * scale;
            const y = corner[1] * scale;
            const rotated_x = x * cos_angle - y * sin_angle;
            const rotated_y = x * sin_angle + y * cos_angle;
            filled_corners[i] = sdl.SDL_Point{
                .x = @as(i32, @intFromFloat(center_x + rotated_x)),
                .y = @as(i32, @intFromFloat(center_y + rotated_y)),
            };
        }
        for (0..4) |i| {
            const next_i = (i + 1) % 4;
            _ = sdl.SDL_RenderDrawLine(
                renderer,
                filled_corners[i].x,
                filled_corners[i].y,
                filled_corners[next_i].x,
                filled_corners[next_i].y,
            );
        }
    }
    
    // Draw outline (white)
    _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    for (0..4) |i| {
        const next_i = (i + 1) % 4;
        _ = sdl.SDL_RenderDrawLine(
            renderer,
            rotated_corners[i].x,
            rotated_corners[i].y,
            rotated_corners[next_i].x,
            rotated_corners[next_i].y,
        );
    }

    // Present frame
    sdl.SDL_RenderPresent(renderer);
}

pub fn main() !void {
    // Initialize SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.debug.print("SDL_Init Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    // Create window
    const window = sdl.SDL_CreateWindow(
        "Ouroboros",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        sdl.SDL_WINDOW_SHOWN,
    ) orelse {
        std.debug.print("SDL_CreateWindow Error: {s}\n", .{sdl.SDL_GetError()});
        return error.WindowCreationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    // Create renderer
    const renderer = sdl.SDL_CreateRenderer(
        window,
        -1,
        sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC,
    ) orelse {
        std.debug.print("SDL_CreateRenderer Error: {s}\n", .{sdl.SDL_GetError()});
        return error.RendererCreationFailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);

    std.debug.print("Window created successfully\n", .{});
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

        // Render the scene
        render(renderer, window, angle);

        // Simple frame delay
        sdl.SDL_Delay(16); // ~60 FPS
    }

    std.debug.print("Application exited successfully\n", .{});
}
