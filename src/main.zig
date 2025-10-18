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
    
    // Create materials for the cubes (separate instances)
    var parent_material = try Material.init(allocator, "resources/shaders/triangle.v.glsl", "resources/shaders/triangle.f.glsl");
    defer parent_material.deinit();
    
    var child_material = try Material.init(allocator, "resources/shaders/triangle.v.glsl", "resources/shaders/triangle.f.glsl");
    defer child_material.deinit();
    
    // Create parent cube at (0, 1, 0) spinning about Z axis
    var parent_cube = try SceneGraphNode.init(allocator, &cube_geometry, &parent_material);
    defer parent_cube.deinit();
    
    // Set parent cube position and properties
    parent_cube.setPosition(zlm.Vec3.new(0.0, 1.0, 0.0));
    parent_cube.setScale(zlm.Vec3.one);
    
    // Parent rotates ONLY about local Z axis
    parent_cube.z_rotation_speed = 1.0;
    
    // Create child cube at (0, 1, 0) relative to parent (no rotation)
    var child_cube = try SceneGraphNode.init(allocator, &cube_geometry, &child_material);
    defer child_cube.deinit();
    
    // Set child cube position (relative to parent) and scale
    child_cube.setPosition(zlm.Vec3.new(0.0, 1.0, 0.0));
    child_cube.setScale(zlm.Vec3.new(0.7, 0.7, 0.7));
    
    // Child has no rotation of its own (already default 0.0)
    
    // Create parent-child relationship
    try parent_cube.addChild(&child_cube);
    
    std.debug.print("Created parent cube at (0, 1, 0) spinning about its local Z axis\n", .{});
    std.debug.print("Created child cube (70%% scale) at (0, 1, 0) relative to parent\n", .{});
    std.debug.print("\nExpected behavior:\n", .{});
    std.debug.print("  - Parent: spins in place at world position (0, 1, 0)\n", .{});
    std.debug.print("  - Child: orbits around parent while rotating to stay aligned with parent frame\n", .{});
    std.debug.print("  - Child initially at world position (0, 2, 0), orbits in XY plane\n", .{});
    

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
        
        // Update scene graph node animation (updates parent and all children)
        parent_cube.update(delta_time);
        
        // Debug: Print transforms periodically
        const debug_interval: u64 = 1000; // milliseconds
        if (current_time % debug_interval < delta_ms) {
            std.debug.print("\n=== Transform Debug (time={d:.3}s) ===\n", .{@as(f32, @floatFromInt(current_time)) / 1000.0});
            
            const parent_local = parent_cube.getTransform();
            const parent_world = parent_cube.getWorldTransform();
            const child_local = child_cube.getTransform();
            const child_world = child_cube.getWorldTransform();
            
            std.debug.print("Parent local position: ({d:.3}, {d:.3}, {d:.3})\n", .{
                parent_local.fields[3][0],
                parent_local.fields[3][1], 
                parent_local.fields[3][2],
            });
            std.debug.print("Parent world position: ({d:.3}, {d:.3}, {d:.3})\n", .{
                parent_world.fields[3][0],
                parent_world.fields[3][1], 
                parent_world.fields[3][2],
            });
            
            // Show parent's rotation matrix elements to see if it's actually rotating
            std.debug.print("Parent rotation (row 0): ({d:.3}, {d:.3}, {d:.3})\n", .{
                parent_world.fields[0][0],
                parent_world.fields[0][1],
                parent_world.fields[0][2],
            });
            
            std.debug.print("Child local position: ({d:.3}, {d:.3}, {d:.3})\n", .{
                child_local.fields[3][0],
                child_local.fields[3][1], 
                child_local.fields[3][2],
            });
            std.debug.print("Child world position: ({d:.3}, {d:.3}, {d:.3})\n", .{
                child_world.fields[3][0],
                child_world.fields[3][1],
                child_world.fields[3][2],
            });
            std.debug.print("Child has parent: {}\n", .{child_cube.parent != null});
            std.debug.print("Child rotation speeds: x={d:.3}, y={d:.3}, z={d:.3}\n", .{
                child_cube.x_rotation_speed,
                child_cube.y_rotation_speed,
                child_cube.z_rotation_speed,
            });
            
            // Check if child world position is changing (should orbit)
            const child_x = child_world.fields[3][0];
            const child_y = child_world.fields[3][1];
            const radius = @sqrt(child_x * child_x + child_y * child_y);
            std.debug.print("Child orbit radius in XY: {d:.3}\n", .{radius});
            
            // Check child's orientation (first basis vector)
            std.debug.print("Child X-axis direction: ({d:.3}, {d:.3}, {d:.3})\n", .{
                child_world.fields[0][0],
                child_world.fields[0][1],
                child_world.fields[0][2],
            });
        }

        // Clear the screen (dark grey background)
        renderer_utils.clearScreen(0.1, 0.1, 0.1, 1.0);

        // Render the scene (renders parent and all children)
        parent_cube.render(&camera);
        
        // Render coordinate axes for reference
        axes_renderer.render(&camera);

        // Swap buffers
        sdl.SDL_GL_SwapWindow(window);
    }

    std.debug.print("Application exited successfully\n", .{});
}
