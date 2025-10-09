# Ouroboros

A cross-platform windowing application built with Zig 0.11.x, building SDL2 from source using git submodules.

## Features

- ✨ Cross-platform support (Windows, Linux, macOS)
- 🏗️ Self-contained SDL2 build from source (no system SDL2 package required)
- 🖼️ Hardware-accelerated rendering
- 🎮 Input event handling (keyboard, window events)
- 🎨 Animated graphics demo with color cycling
- ⌨️ Keyboard shortcuts:
  - `ESC` - Quit application
  - `F11` - Toggle fullscreen
- 🪟 Resizable window with event handling

## Prerequisites

### Zig
This project requires **Zig 0.11.x**. Download from [ziglang.org](https://ziglang.org/download/).

### Platform-Specific System Dependencies

Even though SDL2 is built from source, it still requires platform-specific system libraries for video/audio/input:

#### Linux (Fedora/RHEL)
```bash
sudo dnf install \
    libX11-devel libXext-devel libXcursor-devel \
    libXinerama-devel libXi-devel libXrandr-devel \
    libXScrnSaver-devel libXxf86vm-devel
```

#### Linux (Debian/Ubuntu)
```bash
sudo apt-get install \
    libx11-dev libxext-dev libxcursor-dev \
    libxinerama-dev libxi-dev libxrandr-dev \
    libxss-dev libxxf86vm-dev
```

#### Linux (Arch)
```bash
sudo pacman -S libx11 libxext libxcursor libxinerama libxi libxrandr libxss libxxf86vm
```

#### macOS
No additional dependencies needed beyond Xcode Command Line Tools:
```bash
xcode-select --install
```

#### Windows
No additional dependencies needed. The build will use Windows' built-in APIs.

## Cloning the Repository

This project uses git submodules for SDL2. Clone with:

```bash
git clone --recursive <repository-url>
cd ouroboros
```

Or if you already cloned without `--recursive`:

```bash
git submodule init
git submodule update
```

## Building

```bash
# Build the project
zig build

# Build and run
zig build run

# Run tests
zig build test

# Build with optimizations
zig build -Doptimize=ReleaseFast
```

The compiled binary will be placed in `zig-out/bin/ouroboros`.

## Project Structure

```
ouroboros/
├── build.zig           # Zig build system (includes SDL2 build)
├── src/
│   └── main.zig        # Application entry point
└── vendor/
    └── SDL/            # SDL2 source code (git submodule)
```

## How It Works

### Build System

The `build.zig` file:
1. Compiles SDL2 from source as a static library
2. Automatically selects platform-specific SDL2 source files (Linux/Windows/macOS)
3. Links the static SDL2 library into the final executable
4. No system SDL2 installation required!

### SDL2 Source Build

SDL2 is built from source (tag `release-2.32.10`) with:
- Platform detection for Linux/Windows/macOS
- Appropriate video/audio/input backends for each platform:
  - **Linux**: X11 video, ALSA/PulseAudio audio, evdev input
  - **Windows**: DirectX/GDI video, DirectSound/WASAPI audio, XInput/DirectInput
  - **macOS**: Cocoa video, CoreAudio, IOKit input
- Static linking for portability

## Architecture

The application uses a classic game loop pattern:

1. **Initialization** - Create SDL window and renderer
2. **Event Loop**:
   - **Event handling** - Process user input and system events
   - **Update** - Update application state (delta time based)
   - **Render** - Draw the current frame with animated graphics
   - **Frame limiting** - Maintain consistent 60 FPS
3. **Cleanup** - Destroy SDL resources

The code is structured using an `App` struct that manages:
- SDL2 window and renderer resources
- Event processing and input handling
- Game loop timing and frame rate control
- Proper resource cleanup via `defer`

## Extending

To add your own graphics or logic:

- **Custom rendering**: Modify `App.render()` to add custom drawing code
- **Game logic**: Modify `App.update()` to add custom game logic
- **Input handling**: Add new keyboard/mouse handlers in `App.handleEvents()`
- **Window configuration**: Adjust `WindowConfig` struct values

Example - Adding a keyboard handler:
```zig
c.SDLK_SPACE => {
    std.debug.print("Space pressed!\n", .{});
    // Your code here
},
```

## Troubleshooting

### Build Errors

**"unable to find Dynamic system library 'X11'"**
- Install X11 development packages (see Prerequisites above)

**"This project requires Zig 0.11.x"**
- Make sure you're using Zig version 0.11.x
- Check with: `zig version`

### Runtime Errors

**"SDL_Init Error"**
- Make sure X11 is running (on Linux)
- Check that video drivers are properly installed

## Why Build SDL2 from Source?

Building SDL2 from source as a git submodule provides several advantages:

1. **Version Control**: Exact SDL2 version is pinned and tracked in git
2. **Reproducible Builds**: Everyone gets the same SDL2 version
3. **No External Dependencies**: No need to install system SDL2 packages
4. **Cross-Platform**: Same build process works on all platforms
5. **Customizable**: Can modify SDL2 source if needed
6. **Self-Contained**: The repository contains everything needed (except platform system libraries)

## License

[Specify your license here]

## SDL2 License

SDL2 is licensed under the zlib license. See `vendor/SDL/LICENSE.txt` for details.
