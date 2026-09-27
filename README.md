# The Terminator of Earth

A 3D first-person shooter prototype built in C with OpenGL.

This project starts with a daytime environment sky, using an equirectangular PNG sky texture mapped onto a fullscreen sky dome / sky shader. The code is set up as a foundation for a first-person shooter camera and game loop.

## Features
- C + OpenGL rendering pipeline
- Daytime sky using equirectangular PNG texture
- First-person camera movement
- GLFW + GLEW + GLM setup
- Starting foundation for a FPS game and future combat systems

## Project structure
- `src/` – game code and rendering logic
- `src/shaders/` – GLSL shaders
- `assets/` – put your sky PNGs here

## Build and run

Install dependencies:

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libglfw3-dev libglew-dev libglm-dev libpng-dev
```

Configure and build:

```bash
cmake -S . -B build
cmake --build build
```

Run:

```bash
./build/the_terminator_of_earth
```

## Place your sky texture

Copy your daytime sky PNG into:

```bash
assets/sky_day.png
```

The program will try to load that texture automatically. If it is missing, it renders a fallback gradient sky so the app still runs.

## Controls
- `W`, `A`, `S`, `D` — move
- `Mouse` — look around
- `Esc` — quit

## Future milestones
- Weapon system
- Enemy AI
- Terrain and structures
- HUD and UI
- Audio integration
- Combat gameplay loop
