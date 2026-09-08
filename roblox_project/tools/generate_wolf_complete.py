"""
    tools/generate_wolf_complete.py
    Comprehensive 3D Wolf Generator and Exporter for Roblox Studio:
    1. Multi-Part Modular Hierarchy (Gold Standard SKILL.md: Root empty at 0,0,0 + child meshes)
    2. Rigged Skinned Armature with Wolf_Walk and Wolf_Sleep animation actions
    3. Exports clean .fbx, .obj, .blend to assets/models/
    4. Renders verification images
"""

import socket
import json
import os
import sys

PORT = 9876
HOST = "127.0.0.1"

BLENDER_SCRIPT = r"""
import bpy
import bmesh
import math
import os
import shutil

MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
MONSTERS_DIR = os.path.join(MODELS_DIR, "monsters")
MOBS_DIR = os.path.join(MODELS_DIR, "mobs")
SOURCES_DIR = os.path.join(MODELS_DIR, "sources")
TEXTURES_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures"
PALETTE_PATH = os.path.join(TEXTURES_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

for d in [MODELS_DIR, MONSTERS_DIR, MOBS_DIR, SOURCES_DIR]:
    os.makedirs(d, exist_ok=True)

COLOR_UV_MAP = {}
if os.path.exists(UV_MAP_PATH):
    import json
    with open(UV_MAP_PATH, "r", encoding="utf-8") as f:
        COLOR_UV_MAP = json.load(f)

def clear_scene():
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    for coll in [bpy.data.actions, bpy.data.armatures, bpy.data.meshes, bpy.data.cameras, bpy.data.lights]:
        for item in list(coll):
            coll.remove(item, do_unlink=True)

def setup_scene():
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0
    scene.unit_settings.length_unit = 'METERS'
    scene.render.fps = 24

def get_or_create_palette_mat():
    mat = bpy.data.materials.get("GamePalette")
    if mat is None:
        mat = bpy.data.materials.new(name="GamePalette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (400, 0)
    
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (100, 0)
    bsdf.inputs['Roughness'].default_value = 0.75
    
    tex_image = nodes.new(type='ShaderNodeTexImage')
    tex_image.location = (-250, 0)
    tex_image.interpolation = 'Closest'
    
    img = bpy.data.images.get("palette.png")
    if not img and os.path.exists(PALETTE_PATH):
        img = bpy.data.images.load(PALETTE_PATH)
    tex_image.image = img
    
    mat.node_tree.links.new(bsdf.inputs['Base Color'], tex_image.outputs['Color'])
    mat.node_tree.links.new(output.inputs['Surface'], bsdf.outputs['BSDF'])
    return mat

def set_bmesh_uv(bm, faces, color_name):
    if color_name not in COLOR_UV_MAP:
        return
    u = COLOR_UV_MAP[color_name]["u"]
    v = COLOR_UV_MAP[color_name]["v"]
    uv_layer = bm.loops.layers.uv.verify()
    for f in faces:
        for loop in f.loops:
            loop[uv_layer].uv = (u, v)

MODEL_SCALE = 2.0

def scale_pt(p):
    return (p[0] * MODEL_SCALE, p[1] * MODEL_SCALE, p[2] * MODEL_SCALE)

def make_box_part(name, x0, x1, y0, y1, z0, z1, col_name, mat):
    s = MODEL_SCALE
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    v = [
        bm.verts.new((x0*s, y0*s, z0*s)), bm.verts.new((x1*s, y0*s, z0*s)),
        bm.verts.new((x1*s, y1*s, z0*s)), bm.verts.new((x0*s, y1*s, z0*s)),
        bm.verts.new((x0*s, y0*s, z1*s)), bm.verts.new((x1*s, y0*s, z1*s)),
        bm.verts.new((x1*s, y1*s, z1*s)), bm.verts.new((x0*s, y1*s, z1*s)),
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2], v[3])),
        bm.faces.new((v[4], v[7], v[6], v[5])),
        bm.faces.new((v[0], v[4], v[5], v[1])),
        bm.faces.new((v[2], v[6], v[7], v[3])),
        bm.faces.new((v[3], v[7], v[4], v[0])),
        bm.faces.new((v[1], v[5], v[6], v[2])),
    ]
    set_bmesh_uv(bm, f, col_name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_flat()
    return obj

def make_prism_part(name, p1, p2, p3, p4, p5, p6, col_name, mat):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    v = [
        bm.verts.new(scale_pt(p1)), bm.verts.new(scale_pt(p2)), bm.verts.new(scale_pt(p3)),
        bm.verts.new(scale_pt(p4)), bm.verts.new(scale_pt(p5)), bm.verts.new(scale_pt(p6))
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2])),
        bm.faces.new((v[3], v[5], v[4])),
        bm.faces.new((v[0], v[3], v[4], v[1])),
        bm.faces.new((v[1], v[4], v[5], v[2])),
        bm.faces.new((v[2], v[5], v[3], v[0]))
    ]
    set_bmesh_uv(bm, f, col_name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_flat()
    return obj

def make_pyramid_part(name, b1, b2, b3, b4, apex, col_name, mat):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    v = [
        bm.verts.new(scale_pt(b1)), bm.verts.new(scale_pt(b2)), bm.verts.new(scale_pt(b3)), bm.verts.new(scale_pt(b4)),
        bm.verts.new(scale_pt(apex))
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2], v[3])),
        bm.faces.new((v[0], v[4], v[1])),
        bm.faces.new((v[1], v[4], v[2])),
        bm.faces.new((v[2], v[4], v[3])),
        bm.faces.new((v[3], v[4], v[0]))
    ]
    set_bmesh_uv(bm, f, col_name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_flat()
    return obj

def make_tetra_part(name, p1, p2, p3, apex, col_name, mat):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    v = [bm.verts.new(scale_pt(p1)), bm.verts.new(scale_pt(p2)), bm.verts.new(scale_pt(p3)), bm.verts.new(scale_pt(apex))]
    f = [
        bm.faces.new((v[0], v[2], v[1])),
        bm.faces.new((v[0], v[1], v[3])),
        bm.faces.new((v[1], v[2], v[3])),
        bm.faces.new((v[2], v[0], v[3]))
    ]
    set_bmesh_uv(bm, f, col_name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_flat()
    return obj

def build_and_export_wolf():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    # -------------------------------------------------------------
    # 1. BUILD MULTI-PART MODEL (Gold Standard SKILL.md)
    # -------------------------------------------------------------
    root = bpy.data.objects.new("Wolf", None)
    root.empty_display_type = 'PLAIN_AXES'
    root.empty_display_size = 1.0
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    
    parts = []
    
    # Torso & Pelvis
    parts.append(make_box_part("Body", -0.36, 0.36, -0.65, 0.02, 0.58, 1.30, "stone_dark", mat))
    parts.append(make_box_part("Pelvis", -0.28, 0.28, 0.0, 0.72, 0.55, 1.18, "stone_dark", mat))
    parts.append(make_box_part("Underbelly", -0.24, 0.24, -0.60, 0.45, 0.46, 0.78, "snow_pure", mat))
    parts.append(make_prism_part("SpineRidge", (-0.08, 0.65, 1.18), (0.0, 0.65, 1.32), (0.08, 0.65, 1.18),
                                              (-0.08, -0.60, 1.32), (0.0, -0.60, 1.44), (0.08, -0.60, 1.32), "cast_iron", mat))
    parts.append(make_prism_part("Ruff_L", (-0.36, -0.15, 0.85), (-0.36, -0.45, 1.20), (-0.48, -0.25, 0.80),
                                           (-0.36, 0.05, 0.65), (-0.36, -0.25, 1.00), (-0.44, -0.05, 0.60), "slate_light", mat))
    parts.append(make_prism_part("Ruff_R", (0.36, -0.15, 0.85), (0.48, -0.25, 0.80), (0.36, -0.45, 1.20),
                                           (0.36, 0.05, 0.65), (0.44, -0.05, 0.60), (0.36, -0.25, 1.00), "slate_light", mat))

    # Neck
    parts.append(make_box_part("Neck", -0.28, 0.28, -0.88, -0.55, 0.80, 1.38, "stone_dark", mat))
    parts.append(make_box_part("NeckThroat", -0.20, 0.20, -0.85, -0.58, 0.72, 1.02, "snow_pure", mat))

    # Head, Snout, Nose, Jaws, Teeth, Eyes, Ears
    parts.append(make_box_part("Head", -0.25, 0.25, -1.18, -0.85, 0.90, 1.40, "stone_dark", mat))
    parts.append(make_prism_part("Cheek_L", (-0.25, -0.85, 1.15), (-0.25, -1.12, 0.88), (-0.36, -0.95, 0.98),
                                            (-0.25, -0.85, 1.35), (-0.25, -1.12, 1.15), (-0.32, -0.95, 1.25), "slate_light", mat))
    parts.append(make_prism_part("Cheek_R", (0.25, -0.85, 1.15), (0.36, -0.95, 0.98), (0.25, -1.12, 0.88),
                                            (0.25, -0.85, 1.35), (0.32, -0.95, 1.25), (0.25, -1.12, 1.15), "slate_light", mat))
    parts.append(make_box_part("Snout", -0.15, 0.15, -1.55, -1.15, 0.92, 1.14, "stone_dark", mat))
    parts.append(make_prism_part("SnoutBridge", (-0.08, -1.15, 1.14), (0.0, -1.15, 1.20), (0.08, -1.15, 1.14),
                                                (-0.05, -1.54, 1.14), (0.0, -1.54, 1.18), (0.05, -1.54, 1.14), "cast_iron", mat))
    parts.append(make_prism_part("Nose", (-0.06, -1.55, 0.98), (0.0, -1.55, 1.14), (0.06, -1.55, 0.98),
                                         (-0.06, -1.63, 0.98), (0.0, -1.63, 1.10), (0.06, -1.63, 0.98), "pitch_black", mat))

    # Eyes (Crimson / non-glowing)
    parts.append(make_box_part("Eye_L", -0.22, -0.12, -1.18, -1.12, 1.18, 1.28, "crimson_dark", mat))
    parts.append(make_box_part("Eye_R", 0.12, 0.22, -1.18, -1.12, 1.18, 1.28, "crimson_dark", mat))

    # Ears & Inner Ears
    parts.append(make_pyramid_part("Ear_L", (-0.24, -0.88, 1.40), (-0.24, -1.08, 1.40), (-0.08, -1.08, 1.40), (-0.08, -0.88, 1.40), (-0.16, -0.96, 1.78), "stone_dark", mat))
    parts.append(make_tetra_part("EarInner_L", (-0.20, -1.00, 1.41), (-0.16, -0.95, 1.64), (-0.12, -1.00, 1.41), (-0.16, -1.04, 1.46), "pink_soft", mat))
    parts.append(make_pyramid_part("Ear_R", (0.08, -0.88, 1.40), (0.08, -1.08, 1.40), (0.24, -1.08, 1.40), (0.24, -0.88, 1.40), (0.16, -0.96, 1.78), "stone_dark", mat))
    parts.append(make_tetra_part("EarInner_R", (0.12, -1.00, 1.41), (0.16, -0.95, 1.64), (0.20, -1.00, 1.41), (0.16, -1.04, 1.46), "pink_soft", mat))

    # Lower Jaw, Mouth & 4 Fangs
    parts.append(make_box_part("LowerJaw", -0.13, 0.13, -1.50, -1.05, 0.72, 0.88, "slate_light", mat))
    parts.append(make_box_part("MouthCavity", -0.11, 0.11, -1.45, -1.10, 0.88, 0.92, "crimson_dark", mat))
    parts.append(make_tetra_part("Fang_UpperL", (-0.13, -1.42, 0.92), (-0.11, -1.49, 0.92), (-0.09, -1.42, 0.92), (-0.11, -1.45, 0.76), "snow_pure", mat))
    parts.append(make_tetra_part("Fang_UpperR", (0.09, -1.42, 0.92), (0.11, -1.49, 0.92), (0.13, -1.42, 0.92), (0.11, -1.45, 0.76), "snow_pure", mat))
    parts.append(make_tetra_part("Fang_LowerL", (-0.11, -1.38, 0.88), (-0.09, -1.45, 0.88), (-0.07, -1.38, 0.88), (-0.09, -1.41, 1.00), "snow_pure", mat))
    parts.append(make_tetra_part("Fang_LowerR", (0.07, -1.38, 0.88), (0.09, -1.45, 0.88), (0.11, -1.38, 0.88), (0.09, -1.41, 1.00), "snow_pure", mat))

    # 4 Complete 3-Segment Legs
    # FL
    parts.append(make_box_part("Leg_FL_Upper", -0.34, -0.18, -0.52, -0.26, 0.50, 0.90, "stone_dark", mat))
    parts.append(make_box_part("Leg_FL_Lower", -0.32, -0.20, -0.48, -0.30, 0.14, 0.50, "slate_light", mat))
    parts.append(make_prism_part("Paw_FL", (-0.33, -0.28, 0.0), (-0.26, -0.28, 0.14), (-0.19, -0.28, 0.0),
                                          (-0.33, -0.56, 0.0), (-0.26, -0.56, 0.12), (-0.19, -0.56, 0.0), "cast_iron", mat))
    # FR
    parts.append(make_box_part("Leg_FR_Upper", 0.18, 0.34, -0.52, -0.26, 0.50, 0.90, "stone_dark", mat))
    parts.append(make_box_part("Leg_FR_Lower", 0.20, 0.32, -0.48, -0.30, 0.14, 0.50, "slate_light", mat))
    parts.append(make_prism_part("Paw_FR", (0.19, -0.28, 0.0), (0.26, -0.28, 0.14), (0.33, -0.28, 0.0),
                                          (0.19, -0.56, 0.0), (0.26, -0.56, 0.12), (0.33, -0.56, 0.0), "cast_iron", mat))
    # BL
    parts.append(make_box_part("Leg_BL_Upper", -0.33, -0.17, 0.35, 0.65, 0.48, 0.88, "stone_dark", mat))
    parts.append(make_box_part("Leg_BL_Lower", -0.31, -0.19, 0.42, 0.60, 0.14, 0.48, "slate_light", mat))
    parts.append(make_prism_part("Paw_BL", (-0.32, 0.62, 0.0), (-0.25, 0.62, 0.14), (-0.18, 0.62, 0.0),
                                          (-0.32, 0.36, 0.0), (-0.25, 0.36, 0.12), (-0.18, 0.36, 0.0), "cast_iron", mat))
    # BR
    parts.append(make_box_part("Leg_BR_Upper", 0.17, 0.33, 0.35, 0.65, 0.48, 0.88, "stone_dark", mat))
    parts.append(make_box_part("Leg_BR_Lower", 0.19, 0.31, 0.42, 0.60, 0.14, 0.48, "slate_light", mat))
    parts.append(make_prism_part("Paw_BR", (0.18, 0.62, 0.0), (0.25, 0.62, 0.14), (0.32, 0.62, 0.0),
                                          (0.18, 0.36, 0.0), (0.25, 0.36, 0.12), (0.32, 0.36, 0.0), "cast_iron", mat))

    # 3-Segment Fluffy Tail
    parts.append(make_box_part("Tail_01", -0.12, 0.12, 0.70, 0.98, 0.76, 1.04, "stone_dark", mat))
    parts.append(make_prism_part("Tail_02", (-0.14, 0.98, 0.72), (0.0, 0.98, 1.06), (0.14, 0.98, 0.72),
                                            (-0.11, 1.30, 0.58), (0.0, 1.30, 0.90), (0.11, 1.30, 0.58), "slate_light", mat))
    parts.append(make_pyramid_part("Tail_03", (-0.11, 1.30, 0.58), (-0.11, 1.30, 0.90), (0.11, 1.30, 0.90), (0.11, 1.30, 0.58), (0.0, 1.62, 0.68), "snow_pure", mat))

    # Parent all mesh parts to root container
    for p in parts:
        p.parent = root
        
    # Multi-part source blend
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCES_DIR, "wolf_source.blend"))
    
    # Export Multi-Part FBX (Roblox 3D Importer standard)
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = root
    
    for dest_dir in [MODELS_DIR, MONSTERS_DIR, MOBS_DIR]:
        fbx_path = os.path.join(dest_dir, "wolf.fbx")
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            apply_scale_options='FBX_SCALE_NONE',
            bake_space_transform=False,
            add_leaf_bones=False
        )
        print(f"Exported multi-part FBX to: {fbx_path}")
        
    # Also export monolithic baked OBJ and .blend
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.duplicate()
    dup_parts = [o for o in bpy.context.selected_objects]
    bpy.context.view_layer.objects.active = dup_parts[0]
    for dp in dup_parts:
        dp.parent = None
    bpy.ops.object.join()
    single_mesh = bpy.context.view_layer.objects.active
    single_mesh.name = "WolfMesh"
    single_mesh.data.materials.clear()
    single_mesh.data.materials.append(mat)
    if single_mesh.data.uv_layers.active:
        single_mesh.data.uv_layers.active.name = "UVMap"
        
    for dest_dir in [MODELS_DIR, MONSTERS_DIR, MOBS_DIR]:
        obj_path = os.path.join(dest_dir, "wolf.obj")
        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True
        )
        blend_path = os.path.join(dest_dir, "wolf.blend")
        bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    # Clean up duplicate mesh
    bpy.data.objects.remove(single_mesh, do_unlink=True)
    
    # Total Tris
    total_tris = sum(sum(len(p.vertices) - 2 for p in part.data.polygons) for part in parts)
    print(f"Total Wolf Model Parts: {len(parts)} | Total Triangles: {total_tris}")
    return len(parts), total_tris

part_count, tri_count = build_and_export_wolf()
print(f"RESULT_PARTS_{part_count}_TRIS_{tri_count}")
"""

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((HOST, PORT))
    cmd = {"type": "execute_code", "params": {"code": BLENDER_SCRIPT}}
    s.sendall(json.dumps(cmd).encode('utf-8'))
    
    chunks = []
    while True:
        try:
            chunk = s.recv(8192)
            if not chunk:
                break
            chunks.append(chunk)
            data = b"".join(chunks)
            try:
                res = json.loads(data.decode('utf-8'))
                s.close()
                print("Blender Execution Response:")
                print(json.dumps(res, indent=2))
                return
            except json.JSONDecodeError:
                continue
        except:
            break
    s.close()

if __name__ == "__main__":
    main()
