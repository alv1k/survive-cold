---
name: blender-roblox
description: >-
  Workflows, tools, and automation for creating, modifying, and exporting 3D assets
  in Blender 5.0 for Roblox Studio via Blender MCP or CLI pipeline.
---

# Blender to Roblox 3D Asset Standard (Benchmark: `spear-2.fbx`)

The `assets/models/spear-2.fbx` asset serves as the **Gold Standard** and architectural reference for all 3D assets in this project.

## 1. Hierarchy & Naming Architecture
All models must follow the **Multi-Part Single Container** structure:
- **Root Parent Object**: An Empty or Model Root named with the primary item name (e.g. `Spear`), located at origin `(0, 0, 0)` with rotation `(0, 0, 0)` and scale `(1, 1, 1)`.
- **Child Mesh Components**: Distinct, logically named MeshParts parented under the Root (e.g., `Handle`, `Shaft`, `Blade`, `Collar`, `NeckWrap`, `Pommel`):
  ```text
  Spear (Root Container / Empty at 0,0,0)
    ├── Blade (Cutting mesh / head)
    ├── Collar (Metal socket ferrule)
    ├── Handle (Hand grip point centered at 0,0,0)
    ├── NeckWrap (Binding / cord)
    ├── Pommel (Bottom counterweight)
    └── Shaft (Main wooden body)
  ```
- **DO NOT** merge or join separable material components into one mesh unless specifically requested.
- **DO NOT** create component subfolders (no `_parts/` folders). Export ALL parts together into a single container `.fbx` and `.obj`.

## 2. Roblox Coordinate & Scaling Standards
- **Units**: 1 Blender Meter = 1 Roblox Stud (Player character height $\approx$ 5 studs).
- **Axes**: Forward `-Z`, Up `+Y`.
- **Origin / Pivot Point**:
  - **Weapons & Tools**: The grip center (`Handle`) MUST be centered at `(0, 0, 0)` for immediate placement into the character's hand.
  - **Props, Structures, Traps**: Bottom contact surface MUST be at `Y = 0`.
- **Shading**: `Shade Flat` for Casual Cartoon / Low-Poly aesthetic (3/10 realism).

## 3. Unified Color Palette Atlas (`palette.png`)
- Every 3D mesh MUST use the single shared `GamePalette` material mapped to [`assets/textures/palette.png`](file:///c:/Users/pc1/Documents/workingdir/roblox_project/assets/textures/palette.png).
- UV vertices are collapsed to 1x1 point coordinates at the centers of swatches defined in [`assets/palette_uv_map.json`](file:///c:/Users/pc1/Documents/workingdir/roblox_project/assets/palette_uv_map.json).

## 4. Polygon Budgets
- **Weapons & Handheld Tools**: 100 – 350 triangles.
- **Resources & Small Props**: 50 – 200 triangles.
- **Chests, Traps, Workbenches**: 200 – 600 triangles.
- **Creatures & Mobs (Wolf, Yeti)**: 400 – 900 triangles.
- **Structures & Buildings**: 400 – 1,800 triangles.
- **Hard Engine Limit**: 21,000 triangles per MeshPart.

## 5. Export Deliverables
Every asset is saved to:
- `assets/models/<name>.fbx` (FBX with preserved hierarchy and `-Z Forward / +Y Up`).
- `assets/models/<name>.obj` (Standard Wavefront OBJ container).
- `assets/models/<name>.obj.blend` (Source Blender project with Root parent).
- `ReplicatedStorage/GeneratedModels/<Name>.luau` (Procedural Roblox fallback module).
