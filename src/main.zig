const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

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

        // Clear screen (dark blue)
        _ = sdl.SDL_SetRenderDrawColor(renderer, 30, 30, 60, 255);
        _ = sdl.SDL_RenderClear(renderer);

        // Draw a centered square
        var window_w: i32 = 0;
        var window_h: i32 = 0;
        sdl.SDL_GetWindowSize(window, &window_w, &window_h);
        
        const square_size: i32 = 100;
        const rect = sdl.SDL_Rect{
            .x = @divTrunc(window_w, 2) - @divTrunc(square_size, 2),
            .y = @divTrunc(window_h, 2) - @divTrunc(square_size, 2),
            .w = square_size,
            .h = square_size,
        };
        
        // Fill square (light color)
        _ = sdl.SDL_SetRenderDrawColor(renderer, 200, 180, 150, 255);
        _ = sdl.SDL_RenderFillRect(renderer, &rect);
        
        // Draw outline (white)
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = sdl.SDL_RenderDrawRect(renderer, &rect);

        // Present frame
        sdl.SDL_RenderPresent(renderer);

        // Simple frame delay
        sdl.SDL_Delay(16); // ~60 FPS
    }

    std.debug.print("Application exited successfully\n", .{});
}
