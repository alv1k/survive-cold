---
name: blender-roblox
description: >-
  Workflows, tools, and automation for creating, modifying, and exporting 3D assets
  in Blender 5.0 for Roblox Studio via Blender MCP or CLI pipeline.
---

# Blender to Roblox 3D Asset Workflow

Use this skill when creating or editing 3D models (characters, weapons, props, resources, buildings) in Blender for Roblox Studio.

## 1. Real-time Modeling via Blender MCP
When Blender is running with the BlenderMCP addon active (Port 9876):
- Use Blender MCP tools to create meshes, inspect object hierarchies, adjust vertex positions, and assign materials.
- Verify that every object is centered on its intended Pivot/Origin (`Handle` at `(0,0,0)` for weapons; bottom base at `Y=0` for props/structures).

## 2. Roblox 3D Standards Checklist
- **Units**: 1 Blender Meter = 1 Roblox Stud (Character height $\approx$ 5 studs).
- **Axes**: Forward `-Z`, Up `+Y`.
- **Polycount**:
  - Weapons / Items: 300 - 1,500 tris.
  - Monsters / Pets: 1,500 - 5,000 tris.
  - Structures: 2,000 - 8,000 tris.
  - Hard limit: 21,000 tris per MeshPart.
- **Export Location**: Save all `.obj` / `.fbx` models directly into `assets/models/`.

## 3. Headless CLI Pipeline
If Blender GUI is not running, run the background pipeline:
```powershell
& "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe" --background --python tools/blender_pipeline.py
```
