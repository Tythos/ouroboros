# Project Tasks

## Completed

- [x] SDL2 build for zig linkage of library source from submodule (starting with 0.11.0)

- [x] Basic SDL windowed application with blit drawing and event loop

- [x] Rotating rectangle animation in basic SDL blit rendering

- [x] Updated build.zig version check and path handling for 0.12.1

- [x] Updated build/SDL.zig for ResolvedTarget and path changes for 0.12.1

- [x] Fixed @fieldParentPtr signature for 0.12.1 compatibility

- [x] Migrate to SDL + OpenGL ES context setup with proper attributes

- [x] OpenGL function loading via manual SDL_GL_GetProcAddress

- [x] Shader management system with compilation and error handling

- [x] Runtime shader loading from files (resources.zig)

- [x] Vertex shader with 2D rotation transform

- [x] Fragment shader with interpolated rainbow colors

- [x] Geometry setup with VAO/VBO and vertex attributes (renderer.zig)

- [x] OpenGL render loop with glClear, glDrawArrays, and buffer swapping

- [x] Time-based animation with angle uniform updates

- [x] Resource cleanup and proper deinitialization

- [x] Created multi-file module structure (resources, gl, shader, renderer) to break out logic from main module

- [x] Organize shader source as runtime resources (`.v.glsl`, `.f.glsl` files)

- [x] Updated SDL build specification to properly cache results w/o recompiling intermediate library

- [x] Integrate math library (forked zlm, added via submodule) for Mat4/Vec3 operations with Zig 0.12.1 compatibility fixes

- [x] Change triangle (and scene/camera) transforms (just rotations for now) from 2d into 3d; this should include evolution of matrix derivation and stack management along the lines of a traditional model/view/projecttion, including camera modeling and properties (fov angular dimensions, near/far clipping, etc.)

- [x] Add unit axes visualization for scene frame reference (x=red, y=green, z=blue)

- [x] Add orbit camera controls from mouse input

- [x] Good intermediate extraction of "renderable" model into an object / scene graph node struct

- [x] Add in-module tests to `src/axes.zig` (including test utilities for vector/matrix/vertex data assertions)

- [x] Extend/update in-module tests to `src/camera.zig` (using new test utilities and focusing on mathematical operations)

- [x] Add in-module tests to `src/gl.zig` (using new test utilities)

- [x] Add in-module tests to `src/renderer.zig` (using new test utilities)

- [x] Add in-module tests to `src/resources.zig`

- [x] Add in-module tests to `src/scene_graph_node.zig`

- [x] Add in-module tests to `src/shader.zig`

- [x] Add in-module tests to `src/test_utilities.zig`

- [x] Extract geometry property of scene graph node into its own model, including vertex buffer data; structure; indices; and relevant interfaces

## Active Sprint

- [ ] Extract material properties of scene graph node into a new model, including shaders, programs, loading/unloading, and bindings behaviors

## Backlog

### Epic 2: Content & Scene Architecture

- [ ] Research GLTF structure to inform scene graph design (do this BEFORE implementing scene graph)

- [ ] Implement basic mesh loading (start with OBJ or simple format)

- [ ] Create Material abstraction (shader program + uniforms)

- [ ] Build initial scene data structure (list of renderables)

- [ ] Extract scene into node tree with recursive rendering

- [ ] Implement THREE-like scene graph (Entity → Geometry + Material)

### Epic 3: Renderer Abstraction

- [ ] Consolidate behind OpenGLRenderer interface (design with WebGPU migration in mind)

- [ ] Add render target/canvas abstraction

- [ ] Design command-buffer style API (prepares for WebGPU)

### Epic 4: Asset Pipeline

- [ ] Define resource pack format and runtime loading

- [ ] Implement GLTF import/export

- [ ] Verify Blender → GLTF → Ouroboros workflow

- [ ] Add texture loading and sampling

### Epic 5: Systems & Polish

- [ ] Implement pub-sub event system for subsystem communication

- [ ] Add audio system (SFX + music)

- [ ] Research UI integration options (ImGui, custom, etc.)

- [ ] Add profiling/debug visualization tools

- [ ] Improve memory monitoring and leak detection

### Epic 6: ECS Refactor

- [ ] Separate static scene data from dynamic behavior

- [ ] Prototype ECS for one subsystem (transform/movement)

- [ ] Design component tables and system architecture

- [ ] Migrate systems incrementally

### Epic 7: Platform & Extensibility

- [ ] Evaluate scripting options (Zig/Lua/WASM) based on use case

- [ ] Add embedded console for runtime scripting

- [ ] Research Steam SDK minimal integration (if commercial)

- [ ] Consider physics integration (extend scene graph nodes)

- [ ] Consider networking requirements
