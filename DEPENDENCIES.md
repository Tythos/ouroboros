# System Dependencies Specification

This document formally specifies all external system dependencies required to build and run Ouroboros.

**Version:** 1.0  
**Last Updated:** 2025-10-09

---

## Build-Time Dependencies

These dependencies are required to compile the project from source.

### Mandatory

| Dependency | Version Requirement | Purpose | Package Names |
|------------|-------------------|---------|---------------|
| **Zig** | `0.11.x` (strictly) | Primary compiler | [ziglang.org](https://ziglang.org/download/) |
| **CMake** | `≥ 3.28` | SDL2 build system | `cmake` (all platforms) |
| **C Compiler** | Any modern C99+ | SDL2 compilation | gcc, clang, msvc (platform-specific) |

### Platform-Specific: Linux

All Linux distributions require X11 development libraries. These provide:
- Window management (libX11)
- Display configuration (libXrandr, libXinerama)
- Input handling (libXi)
- Cursor management (libXcursor)
- Extensions (libXext, libXss, libXxf86vm)

| Distribution Family | Install Command |
|--------------------|-----------------| 
| **Fedora / RHEL / CentOS** | `sudo dnf install -y libX11-devel libXext-devel libXcursor-devel libXinerama-devel libXi-devel libXrandr-devel libXScrnSaver-devel libXxf86vm-devel` |
| **Debian / Ubuntu** | `sudo apt-get install -y libx11-dev libxext-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libxss-dev libxxf86vm-dev` |
| **Arch Linux** | `sudo pacman -S --needed libx11 libxext libxcursor libxinerama libxi libxrandr libxss libxxf86vm` |

**Note:** Package names differ slightly between distributions (`-devel` vs `-dev` suffix).

### Platform-Specific: macOS

| Dependency | Version | Install Command | Purpose |
|------------|---------|----------------|---------|
| **Xcode Command Line Tools** | Latest | `xcode-select --install` | Provides system frameworks (Cocoa, IOKit, CoreAudio, etc.) |

### Platform-Specific: Windows

**No additional dependencies required.** Windows SDK provides all necessary libraries (User32, GDI32, WinMM, etc.).

---

## Runtime Dependencies

The compiled executable requires only:

1. **Standard C Library** (libc/msvcrt)
   - Provided by operating system
   - Statically linked on some platforms

2. **Platform System Libraries**
   - Same libraries required at build time (but runtime versions, not `-dev` packages)
   - Automatically present if build succeeded

**Note:** SDL2 is statically linked into the executable. No SDL2 runtime installation is required.

---

## Why These Dependencies?

### X11 Libraries (Linux)

SDL2 uses X11 as its primary video backend on Linux. Even though we build SDL2 from source, it dynamically links to X11 system libraries because:

1. X11 is the standard Linux windowing system
2. X11 libraries are ABI-stable across distributions
3. Static linking X11 is not recommended (size/compatibility issues)

### System Frameworks (macOS)

macOS frameworks (Cocoa, IOKit, etc.) are part of the OS and cannot be statically linked. SDL2 uses these for:
- Window management (Cocoa)
- Input devices (IOKit)
- Audio output (CoreAudio)

### Windows APIs

Windows provides all windowing/graphics APIs as part of the OS. No separate packages needed.

---

## Build Process Summary

```
┌─────────────┐
│ Zig Build   │
│  (build.zig)│
└─────┬───────┘
      │
      ├─> CMake Configure (SDL/CMakeLists.txt)
      │   └─> Detect platform libraries
      │   └─> Generate build files
      │
      ├─> CMake Build
      │   └─> Compile ~450 SDL2 .c files
      │   └─> Create libSDL2.a (static library)
      │
      ├─> Compile main.zig
      │
      └─> Link Executable
          ├─> libSDL2.a (static)
          ├─> System libraries (dynamic)
          │   ├─> Linux: X11, Xext, etc.
          │   ├─> macOS: Cocoa.framework, etc.
          │   └─> Windows: user32.lib, etc.
          └─> Output: zig-out/bin/ouroboros
```

---

## Verification

### Check Zig Version
```bash
zig version
# Should output: 0.11.x
```

### Check CMake Version
```bash
cmake --version
# Should be ≥ 3.28
```

### Check X11 Libraries (Linux)
```bash
pkg-config --modversion x11 xext xcursor xinerama xi xrandr xss xxf86vm
# Should output version numbers for each
```

### Check Xcode Tools (macOS)
```bash
xcode-select -p
# Should output a path (e.g., /Library/Developer/CommandLineTools)
```

---

## Minimal System Requirements

- **CPU:** x86_64 / ARM64
- **RAM:** 512 MB (build requires ~1 GB)
- **Disk:** 50 MB for source + 200 MB for build artifacts
- **Display:** Any resolution with OpenGL ES 2.0 support

---

## Optional Dependencies

None at this time. All features use mandatory dependencies.

---

## Dependency Rationale

**Q: Why not use system SDL2 package?**  
A: Building from source via submodule ensures consistent SDL2 version across all platforms and simplifies dependency management.

**Q: Why not build X11 from source?**  
A: X11 is deeply integrated with the Linux graphics stack. Using system packages is standard practice and ensures compatibility with the user's display server.

**Q: Can we remove X11 dependency?**  
A: Yes, by using Wayland backend or framebuffer, but X11 is most widely supported. This could be made optional in future versions.

---

## Version History

- **1.0** (2025-10-09): Initial specification

