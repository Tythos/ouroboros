const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const WindowConfig = struct {
    title: [*:0]const u8 = "Ouroboros",
    width: i32 = 800,
    height: i32 = 600,
    fps: u32 = 60,
};

const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool,
    config: WindowConfig,

    fn init(config: WindowConfig) !App {
        // Initialize SDL
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            std.debug.print("SDL_Init Error: {s}\n", .{c.SDL_GetError()});
            return error.SDLInitFailed;
        }

        // Create window
        const window = c.SDL_CreateWindow(
            config.title,
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            config.width,
            config.height,
            c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_RESIZABLE,
        ) orelse {
            std.debug.print("SDL_CreateWindow Error: {s}\n", .{c.SDL_GetError()});
            c.SDL_Quit();
            return error.WindowCreationFailed;
        };

        // Create renderer with hardware acceleration and VSync
        const renderer = c.SDL_CreateRenderer(
            window,
            -1,
            c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC,
        ) orelse {
            std.debug.print("SDL_CreateRenderer Error: {s}\n", .{c.SDL_GetError()});
            c.SDL_DestroyWindow(window);
            c.SDL_Quit();
            return error.RendererCreationFailed;
        };

        std.debug.print("Window created successfully\n", .{});
        std.debug.print("Press ESC or close the window to quit\n", .{});

        return App{
            .window = window,
            .renderer = renderer,
            .running = true,
            .config = config,
        };
    }

    fn deinit(self: *App) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
        std.debug.print("Application cleaned up\n", .{});
    }

    fn handleEvents(self: *App) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    self.running = false;
                },
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_ESCAPE => {
                            std.debug.print("ESC pressed - quitting\n", .{});
                            self.running = false;
                        },
                        c.SDLK_F11 => {
                            self.toggleFullscreen();
                        },
                        else => {},
                    }
                },
                c.SDL_WINDOWEVENT => {
                    if (event.window.event == c.SDL_WINDOWEVENT_RESIZED) {
                        std.debug.print("Window resized to {}x{}\n", .{
                            event.window.data1,
                            event.window.data2,
                        });
                    }
                },
                else => {},
            }
        }
    }

    fn toggleFullscreen(self: *App) void {
        const flags = c.SDL_GetWindowFlags(self.window);
        if ((flags & c.SDL_WINDOW_FULLSCREEN_DESKTOP) != 0) {
            _ = c.SDL_SetWindowFullscreen(self.window, 0);
            std.debug.print("Exiting fullscreen\n", .{});
        } else {
            _ = c.SDL_SetWindowFullscreen(self.window, c.SDL_WINDOW_FULLSCREEN_DESKTOP);
            std.debug.print("Entering fullscreen\n", .{});
        }
    }

    fn update(self: *App, delta_time: f32) void {
        _ = self;
        _ = delta_time;
        // Update game logic here
        // delta_time is the time elapsed since last frame in seconds
    }

    fn render(self: *App) void {
        // Get time-based color animation
        const ticks = c.SDL_GetTicks();
        const time: f32 = @as(f32, @floatFromInt(ticks)) / 1000.0;
        
        // Create a smooth color cycle
        const r: u8 = @intFromFloat((@sin(time * 0.5) * 0.5 + 0.5) * 128.0 + 64.0);
        const g: u8 = @intFromFloat((@sin(time * 0.7 + 2.0) * 0.5 + 0.5) * 128.0 + 64.0);
        const b: u8 = @intFromFloat((@sin(time * 0.3 + 4.0) * 0.5 + 0.5) * 128.0 + 64.0);

        // Clear screen with animated background color
        _ = c.SDL_SetRenderDrawColor(self.renderer, r, g, b, 255);
        _ = c.SDL_RenderClear(self.renderer);

        // Draw a rotating rectangle in the center
        var window_w: i32 = 0;
        var window_h: i32 = 0;
        c.SDL_GetWindowSize(self.window, &window_w, &window_h);

        const rect_size: i32 = 100;
        const center_x = @divTrunc(window_w, 2);
        const center_y = @divTrunc(window_h, 2);

        // Draw central rectangle with inverted colors
        const rect = c.SDL_Rect{
            .x = center_x - @divTrunc(rect_size, 2),
            .y = center_y - @divTrunc(rect_size, 2),
            .w = rect_size,
            .h = rect_size,
        };

        _ = c.SDL_SetRenderDrawColor(self.renderer, 255 - r, 255 - g, 255 - b, 255);
        _ = c.SDL_RenderFillRect(self.renderer, &rect);

        // Draw outline
        _ = c.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderDrawRect(self.renderer, &rect);

        // Present the rendered frame
        c.SDL_RenderPresent(self.renderer);
    }

    fn run(self: *App) void {
        const frame_delay = 1000 / self.config.fps;
        var last_time = c.SDL_GetTicks();

        while (self.running) {
            const frame_start = c.SDL_GetTicks();

            // Calculate delta time
            const current_time = c.SDL_GetTicks();
            const delta_ms = current_time - last_time;
            const delta_time: f32 = @as(f32, @floatFromInt(delta_ms)) / 1000.0;
            last_time = current_time;

            // Handle input events
            self.handleEvents();

            // Update game state
            self.update(delta_time);

            // Render
            self.render();

            // Frame rate limiting
            const frame_time = c.SDL_GetTicks() - frame_start;
            if (frame_time < frame_delay) {
                c.SDL_Delay(frame_delay - frame_time);
            }
        }
    }
};

pub fn main() !void {
    const config = WindowConfig{
        .title = "Ouroboros - SDL2 Window Demo",
        .width = 800,
        .height = 600,
        .fps = 60,
    };

    var app = try App.init(config);
    defer app.deinit();

    app.run();

    std.debug.print("Application exited successfully\n", .{});
}
