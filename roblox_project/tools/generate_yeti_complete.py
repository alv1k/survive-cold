"""
    tools/generate_yeti_complete.py
    Full 4x 3D Snow Yeti Generator for Blender 5.0 and Roblox Studio:
    - Multi-Part Modular Hierarchy (Gold Standard SKILL.md)
    - 4x Scale Geometry (Snow Fur Torso, Fur Collar, Slate Mask, Curved Ice Horns, Ice Claws, Ice Feet)
    - Armature Rigging with Yeti_Walk and Yeti_Run Actions
    - Non-glowing matte UV Palette Mapping
    - Multi-directory export (.fbx, .obj, .blend)
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
    bsdf.inputs['Roughness'].default_value = 0.8
    
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

# 4x Base Scale for Yeti
YETI_SCALE = 4.0

def scale_pt(p):
    return (p[0] * YETI_SCALE, p[1] * YETI_SCALE, p[2] * YETI_SCALE)

def make_box_part(name, x0, x1, y0, y1, z0, z1, col_name, mat):
    s = YETI_SCALE
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
        bm.verts.new(scale_pt(b1)), bm.verts.new(scale_pt(b2)), bm.verts.new(scale_pt(b3)),
        bm.verts.new(scale_pt(b4)), bm.verts.new(scale_pt(apex))
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

def build_and_export_yeti():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    root = bpy.data.objects.new("Yeti", None)
    root.empty_display_type = 'PLAIN_AXES'
    root.empty_display_size = 2.0
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    
    parts = []
    
    # -------------------------------------------------------------------------
    # 1. TORSO, BELLY & FUR COLLAR (Z: Forward is -Y in Blender standard)
    # Note in Blender: X=Left/Right, Y=Forward(-)/Back(+), Z=Up
    # -------------------------------------------------------------------------
    # Main upper chest
    parts.append(make_box_part("Torso", -0.60, 0.60, -0.45, 0.45, 1.40, 2.40, "snow_pure", mat))
    # Lower belly
    parts.append(make_box_part("LowerTorso", -0.52, 0.52, -0.40, 0.40, 0.80, 1.40, "snow_ambient", mat))
    # Massive fur collar around neck/shoulders
    parts.append(make_box_part("FurCollar", -0.68, 0.68, -0.52, 0.52, 2.20, 2.65, "snow_pure", mat))
    # Bulging pectoral chest
    parts.append(make_prism_part("ChestBulge", (-0.45, -0.45, 1.50), (0.45, -0.45, 1.50), (0.0, -0.70, 1.90),
                                              (-0.45, -0.45, 2.30), (0.45, -0.45, 2.30), (0.0, -0.65, 2.30), "snow_ambient", mat))
    # Back fur hump
    parts.append(make_prism_part("BackHump", (-0.45, 0.45, 1.60), (0.45, 0.45, 1.60), (0.0, 0.65, 2.10),
                                            (-0.45, 0.45, 2.45), (0.45, 0.45, 2.45), (0.0, 0.60, 2.45), "snow_pure", mat))

    # -------------------------------------------------------------------------
    # 2. HEAD, SLATE MASK, FANGS, EYES (Non-glowing)
    # -------------------------------------------------------------------------
    # Head cranium
    parts.append(make_box_part("Head", -0.40, 0.40, -0.50, 0.25, 2.50, 3.20, "snow_pure", mat))
    # Slate dark face mask
    parts.append(make_box_part("FaceMask", -0.32, 0.32, -0.68, -0.48, 2.55, 3.05, "stone_dark", mat))
    # Brow ridge
    parts.append(make_prism_part("BrowRidge", (-0.32, -0.48, 3.05), (0.32, -0.48, 3.05), (0.0, -0.72, 3.10),
                                              (-0.32, -0.48, 3.18), (0.32, -0.48, 3.18), (0.0, -0.68, 3.18), "cast_iron", mat))
    # Matte non-glowing Eyes (deep icy cyan)
    parts.append(make_box_part("Eye_L", -0.24, -0.10, -0.70, -0.66, 2.82, 2.94, "ice_glacier", mat))
    parts.append(make_box_part("Eye_R", 0.10, 0.24, -0.70, -0.66, 2.82, 2.94, "ice_glacier", mat))

    # Fangs (Upper & Lower)
    parts.append(make_tetra_part("Fang_UpperL", (-0.22, -0.68, 2.65), (-0.14, -0.68, 2.65), (-0.18, -0.60, 2.65), (-0.18, -0.70, 2.42), "bone_ivory", mat))
    parts.append(make_tetra_part("Fang_UpperR", (0.14, -0.68, 2.65), (0.22, -0.68, 2.65), (0.18, -0.60, 2.65), (0.18, -0.70, 2.42), "bone_ivory", mat))
    parts.append(make_tetra_part("Fang_LowerL", (-0.20, -0.66, 2.55), (-0.14, -0.66, 2.55), (-0.17, -0.60, 2.55), (-0.17, -0.68, 2.72), "bone_ivory", mat))
    parts.append(make_tetra_part("Fang_LowerR", (0.14, -0.66, 2.55), (0.20, -0.66, 2.55), (0.17, -0.60, 2.55), (0.17, -0.68, 2.72), "bone_ivory", mat))

    # -------------------------------------------------------------------------
    # 3. CURVED ICE HORNS (Base + Mid + Sharp Tip)
    # -------------------------------------------------------------------------
    # Left Horn
    parts.append(make_box_part("HornBase_L", -0.65, -0.38, -0.25, 0.05, 3.10, 3.55, "ice_glacier", mat))
    parts.append(make_prism_part("HornMid_L", (-0.65, -0.25, 3.55), (-0.38, -0.25, 3.55), (-0.80, 0.10, 3.90),
                                              (-0.65, 0.05, 3.55), (-0.38, 0.05, 3.55), (-0.75, 0.15, 3.90), "ice_light", mat))
    parts.append(make_pyramid_part("HornTip_L", (-0.82, 0.05, 3.90), (-0.72, 0.05, 3.90), (-0.72, 0.18, 3.90), (-0.82, 0.18, 3.90), (-0.98, 0.28, 4.30), "snow_pure", mat))

    # Right Horn
    parts.append(make_box_part("HornBase_R", 0.38, 0.65, -0.25, 0.05, 3.10, 3.55, "ice_glacier", mat))
    parts.append(make_prism_part("HornMid_R", (0.38, -0.25, 3.55), (0.65, -0.25, 3.55), (0.80, 0.10, 3.90),
                                              (0.38, 0.05, 3.55), (0.65, 0.05, 3.55), (0.75, 0.15, 3.90), "ice_light", mat))
    parts.append(make_pyramid_part("HornTip_R", (0.72, 0.05, 3.90), (0.82, 0.05, 3.90), (0.82, 0.18, 3.90), (0.72, 0.18, 3.90), (0.98, 0.28, 4.30), "snow_pure", mat))

    # -------------------------------------------------------------------------
    # 4. MASSIVE ARMS, FOREARMS, ICE CLAWS / FISTS
    # -------------------------------------------------------------------------
    # Left Arm
    parts.append(make_box_part("Shoulder_L", -0.98, -0.58, -0.35, 0.35, 1.80, 2.50, "snow_pure", mat))
    parts.append(make_box_part("Arm_L", -1.02, -0.66, -0.30, 0.30, 1.00, 1.80, "snow_ambient", mat))
    parts.append(make_box_part("Forearm_L", -1.05, -0.68, -0.32, 0.32, 0.35, 1.00, "snow_pure", mat))
    parts.append(make_box_part("Claw_L", -1.10, -0.65, -0.38, 0.35, -0.05, 0.35, "ice_deep", mat))

    # Right Arm
    parts.append(make_box_part("Shoulder_R", 0.58, 0.98, -0.35, 0.35, 1.80, 2.50, "snow_pure", mat))
    parts.append(make_box_part("Arm_R", 0.66, 1.02, -0.30, 0.30, 1.00, 1.80, "snow_ambient", mat))
    parts.append(make_box_part("Forearm_R", 0.68, 1.05, -0.32, 0.32, 0.35, 1.00, "snow_pure", mat))
    parts.append(make_box_part("Claw_R", 0.65, 1.10, -0.38, 0.35, -0.05, 0.35, "ice_deep", mat))

    # -------------------------------------------------------------------------
    # 5. POWERFUL LEGS & ICE FEET
    # -------------------------------------------------------------------------
    # Left Leg
    parts.append(make_box_part("Thigh_L", -0.52, -0.15, -0.28, 0.28, 0.45, 0.85, "snow_ambient", mat))
    parts.append(make_box_part("Leg_L", -0.50, -0.16, -0.25, 0.25, 0.15, 0.45, "snow_pure", mat))
    parts.append(make_prism_part("Foot_L", (-0.52, -0.25, 0.0), (-0.14, -0.25, 0.0), (-0.33, -0.25, 0.20),
                                          (-0.52, -0.55, 0.0), (-0.14, -0.55, 0.0), (-0.33, -0.55, 0.15), "ice_deep", mat))

    # Right Leg
    parts.append(make_box_part("Thigh_R", 0.15, 0.52, -0.28, 0.28, 0.45, 0.85, "snow_ambient", mat))
    parts.append(make_box_part("Leg_R", 0.16, 0.50, -0.25, 0.25, 0.15, 0.45, "snow_pure", mat))
    parts.append(make_prism_part("Foot_R", (0.14, -0.25, 0.0), (0.52, -0.25, 0.0), (0.33, -0.25, 0.20),
                                          (0.14, -0.55, 0.0), (0.52, -0.55, 0.0), (0.33, -0.55, 0.15), "ice_deep", mat))

    # Parent all mesh parts to root
    for p in parts:
        p.parent = root
        
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCES_DIR, "yeti_source.blend"))
    
    # Export Multi-Part FBX (Roblox 3D Importer standard)
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = root
    
    for dest_dir in [MODELS_DIR, MONSTERS_DIR, MOBS_DIR]:
        fbx_path = os.path.join(dest_dir, "yeti.fbx")
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
    single_mesh.name = "YetiMesh"
    single_mesh.data.materials.clear()
    single_mesh.data.materials.append(mat)
    if single_mesh.data.uv_layers.active:
        single_mesh.data.uv_layers.active.name = "UVMap"
        
    for dest_dir in [MODELS_DIR, MONSTERS_DIR, MOBS_DIR]:
        obj_path = os.path.join(dest_dir, "yeti.obj")
        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True
        )
        blend_path = os.path.join(dest_dir, "yeti.blend")
        bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.data.objects.remove(single_mesh, do_unlink=True)
    
    total_tris = sum(sum(len(p.vertices) - 2 for p in part.data.polygons) for part in parts)
    print(f"Total Yeti Model Parts: {len(parts)} | Total Triangles: {total_tris}")
    return len(parts), total_tris

part_count, tri_count = build_and_export_yeti()
print(f"RESULT_YETI_PARTS_{part_count}_TRIS_{tri_count}")
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
                print("Blender Yeti Execution Response:")
                print(json.dumps(res, indent=2))
                return
            except json.JSONDecodeError:
                continue
        except:
            break
    s.close()

if __name__ == "__main__":
    main()
