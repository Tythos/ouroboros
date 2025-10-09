# Ouroboros

Cross-platform windowing application built with Zig 0.11.x and SDL2 (compiled from source via git submodule).

## System Requirements

> **📋 For detailed dependency specification, see [DEPENDENCIES.md](DEPENDENCIES.md)**

### Build Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Zig | 0.11.x | Compiler (strictly required) |
| CMake | ≥3.28 | SDL2 build system |
| C Compiler | Any | SDL2 compilation (gcc/clang/msvc) |

### Platform-Specific System Libraries

SDL2 requires platform-specific system libraries for video, audio, and input even when built from source. These must be installed as system packages:

#### Linux (Required)

**Fedora/RHEL:**
```bash
sudo dnf install -y \
    libX11-devel \
    libXext-devel \
    libXcursor-devel \
    libXinerama-devel \
    libXi-devel \
    libXrandr-devel \
    libXScrnSaver-devel \
    libXxf86vm-devel
```

**Debian/Ubuntu:**
```bash
sudo apt-get install -y \
    libx11-dev \
    libxext-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxi-dev \
    libxrandr-dev \
    libxss-dev \
    libxxf86vm-dev
```

**Arch:**
```bash
sudo pacman -S --needed \
    libx11 \
    libxext \
    libxcursor \
    libxinerama \
    libxi \
    libxrandr \
    libxss \
    libxxf86vm
```

**Purpose:** X11 window system libraries for video output, input handling, and display management.

#### macOS (Required)

```bash
xcode-select --install
```

**Purpose:** Provides system frameworks (Cocoa, IOKit, CoreAudio, etc.) that SDL2 uses.

#### Windows (Required)

No additional packages needed. SDL2 uses built-in Win32 APIs (User32, GDI32, etc.).

## Building from Source

### 1. Clone with Submodules

```bash
git clone --recursive <repository-url>
cd ouroboros
```

Or if already cloned:
```bash
git submodule update --init --recursive
```

### 2. Install System Dependencies

Install the platform-specific libraries listed above for your operating system.

### 3. Build

```bash
zig build          # Build only
zig build run      # Build and run
zig build -Doptimize=ReleaseFast  # Optimized build
```

**Note:** First build will take several minutes as CMake compiles SDL2 (~450 source files). Subsequent builds are much faster due to caching.

## Project Structure

```
ouroboros/
├── build.zig              # Main build configuration
├── build/
│   └── SDL.zig           # SDL2 build integration module
├── src/
│   └── main.zig          # Application entry point
└── SDL/                  # SDL2 source (git submodule)
    ├── CMakeLists.txt    # SDL2's cmake configuration
    ├── include/          # SDL2 headers
    └── src/              # SDL2 source code
```

## Build System Details

1. **CMake invocation** (`build/SDL.zig`):
   - Configures SDL2 build in `SDL/build/` directory
   - Builds static library (`libSDL2.a` or `SDL2-static.lib`)
   - Only runs when SDL2 changes

2. **Zig build** (`build.zig`):
   - Depends on CMake build step
   - Links SDL2 static library into executable
   - Links platform-specific system libraries
   - Compiles application code

## Troubleshooting

### Build Error: "unable to find Dynamic system library 'X11'"

**Cause:** X11 development libraries not installed.

**Solution:** Install the `-devel` (Fedora/RHEL) or `-dev` (Debian/Ubuntu) packages listed above.

### Build Error: "This project requires Zig 0.11.x"

**Cause:** Wrong Zig version.

**Solution:** Install Zig 0.11.x from [ziglang.org/download](https://ziglang.org/download/).

### Build Error: "cmake: command not found"

**Cause:** CMake not installed.

**Solution:**
- Fedora/RHEL: `sudo dnf install cmake`
- Debian/Ubuntu: `sudo apt-get install cmake`
- macOS: `brew install cmake`
- Windows: Download from [cmake.org](https://cmake.org/download/)

## Runtime Dependencies

The compiled binary has no runtime dependencies beyond:
- Standard C library (libc)
- Platform system libraries (already installed if build succeeded)

The binary is statically linked with SDL2, so no SDL2 runtime installation is needed.

## Features

- Cross-platform window creation and management
- Hardware-accelerated rendering (OpenGL ES 2.0)
- Event handling (keyboard, mouse, window resize)
- Keyboard shortcuts:
  - `ESC` - Quit application
  - `F11` - Toggle fullscreen

## License

[Specify your license]

SDL2 is licensed under the zlib license. See `SDL/LICENSE.txt`.
