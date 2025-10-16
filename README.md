# Ouroboros

Cross-platform windowing application built with Zig 0.11.x and SDL2 (compiled from source via git submodule).

## System Requirements

Specific version requirements for build tools include:

* Zig == 0.11.x

* CMake >= 3.28

SDL2 is referenced via git submodule and built from source, but may require a minimum set of system-specific platform dependencies:

* *LINUX*: `X11-devel`, `Xext-devel`, `Xcursor-devel`, `Xinerama-devel`, `Xi-devel`, `Xrandr-devel`, `XScrnSaver-devel`, `Xxf86vm-devel`, `mesa-libGL-devel`, `mesa-libGLU-devel` (debian and arch packages may have slightly different names; when installed via system package manager, `lib` prefix will often be needed)

* *MACOS*: `xcode-select --all` can be used to install relevant development libraries

* *WINDOWS*: Existing system APIs should be sufficient

## Building and Testing

First, once this project has been cloned, ensure the submodules are correctly initiated:

```bash
git submodule update --init
```

You should then be able to build (including the SDL2 library) from source:

```bash
zig build
```

You can launch the test program, which will show a basic square fill on a background using SDL blit mechanics:

```bash
zig build run
```
