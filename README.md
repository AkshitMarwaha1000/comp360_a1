# COMP360 – Assignment 1: Procedural Terrain Generator

## Project Overview
This project implements a procedural terrain generator in Godot using GDScript.  
The terrain is built with a grid mesh and heightmap driven by fractal noise.

## Parameters Used
- Img Size: 128  
- Rows: 64  
- Cols: 64  
- Grid W: 20  
- Grid H: 20  
- Height Scale: 12  
- Seed: 1337  
- Frequency: 0.02  
- Octaves: 4  

## Instructions
1. Open `Terrain.tscn` in Godot.  
2. Run the scene to generate the terrain.  
3. Press **R** to regenerate (if randomize_seed_on_regen is enabled).  
4. Adjust parameters in the Inspector (`TerrainRoot` → `terrain_generator.gd`) to experiment.

## Screenshots
Example run with parameters listed above:

![Terrain Screenshot](screenshot1.png)

## Notes
- Default values are set for reproducibility (Seed = 1337).  
- Increasing `Img Size` (e.g., 256) produces higher detail but requires more compute.  
- This demo scales: a 64×64 grid builds 4225 vertices and 8192 triangles.
