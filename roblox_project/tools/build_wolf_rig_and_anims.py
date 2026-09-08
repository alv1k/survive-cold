"""
tools/build_wolf_rig_and_anims.py
Generates a stylized low-poly wolf model in Blender 5.0 with full armature rig,
vertex skinning, and Walk and Sleep animation cycles, then exports to FBX & Blend.
"""

import socket
import json
import base64
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

PORT = 9876
HOST = "127.0.0.1"

BLENDER_CODE = r"""
import bpy
import bmesh
import math
import os

MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
MONSTERS_DIR = os.path.join(MODELS_DIR, "monsters")
MOBS_DIR = os.path.join(MODELS_DIR, "mobs")
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(MONSTERS_DIR, exist_ok=True)
os.makedirs(MOBS_DIR, exist_ok=True)

PALETTE_PATH = os.path.join(r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures", "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

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
    
    # Remove orphan actions, armatures, meshes, materials, cameras, lights
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act, do_unlink=True)
    for arm in list(bpy.data.armatures):
        bpy.data.armatures.remove(arm, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh, do_unlink=True)
    for cam in list(bpy.data.cameras):
        bpy.data.cameras.remove(cam, do_unlink=True)
    for light in list(bpy.data.lights):
        bpy.data.lights.remove(light, do_unlink=True)

def setup_roblox_scene():
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

def add_box(bm, x0, x1, y0, y1, z0, z1, col_name=None):
    v = [
        bm.verts.new((x0, y0, z0)), bm.verts.new((x1, y0, z0)),
        bm.verts.new((x1, y1, z0)), bm.verts.new((x0, y1, z0)),
        bm.verts.new((x0, y0, z1)), bm.verts.new((x1, y0, z1)),
        bm.verts.new((x1, y1, z1)), bm.verts.new((x0, y1, z1)),
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2], v[3])),
        bm.faces.new((v[4], v[7], v[6], v[5])),
        bm.faces.new((v[0], v[4], v[5], v[1])),
        bm.faces.new((v[2], v[6], v[7], v[3])),
        bm.faces.new((v[3], v[7], v[4], v[0])),
        bm.faces.new((v[1], v[5], v[6], v[2])),
    ]
    if col_name:
        set_bmesh_uv(bm, f, col_name)
    return v, f

def add_prism(bm, p1, p2, p3, p4, p5, p6, col_name=None):
    v = [
        bm.verts.new(p1), bm.verts.new(p2), bm.verts.new(p3),
        bm.verts.new(p4), bm.verts.new(p5), bm.verts.new(p6)
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2])),
        bm.faces.new((v[3], v[5], v[4])),
        bm.faces.new((v[0], v[3], v[4], v[1])),
        bm.faces.new((v[1], v[4], v[5], v[2])),
        bm.faces.new((v[2], v[5], v[3], v[0]))
    ]
    if col_name:
        set_bmesh_uv(bm, f, col_name)
    return v, f

def add_pyramid(bm, b1, b2, b3, b4, apex, col_name=None):
    v = [
        bm.verts.new(b1), bm.verts.new(b2), bm.verts.new(b3), bm.verts.new(b4),
        bm.verts.new(apex)
    ]
    f = [
        bm.faces.new((v[0], v[1], v[2], v[3])),
        bm.faces.new((v[0], v[4], v[1])),
        bm.faces.new((v[1], v[4], v[2])),
        bm.faces.new((v[2], v[4], v[3])),
        bm.faces.new((v[3], v[4], v[0]))
    ]
    if col_name:
        set_bmesh_uv(bm, f, col_name)
    return v, f

def add_tetra(bm, p1, p2, p3, apex, col_name=None):
    v = [bm.verts.new(p1), bm.verts.new(p2), bm.verts.new(p3), bm.verts.new(apex)]
    f = [
        bm.faces.new((v[0], v[2], v[1])),
        bm.faces.new((v[0], v[1], v[3])),
        bm.faces.new((v[1], v[2], v[3])),
        bm.faces.new((v[2], v[0], v[3]))
    ]
    if col_name:
        set_bmesh_uv(bm, f, col_name)
    return v, f

def build_wolf_asset():
    clear_scene()
    setup_roblox_scene()
    
    # -------------------------------------------------------------
    # 1. BUILD MESH WITH GEOMETRIC VERTEX GROUP ASSIGNMENTS
    # -------------------------------------------------------------
    mesh = bpy.data.meshes.new("WolfMesh")
    bm = bmesh.new()
    
    vg_vert_indices = {
        "Pelvis": [],
        "Spine": [],
        "Neck": [],
        "Head": [],
        "Jaw": [],
        "Tail_01": [],
        "Tail_02": [],
        "Tail_03": [],
        "Leg_FL_Upper": [],
        "Leg_FL_Lower": [],
        "Paw_FL": [],
        "Leg_FR_Upper": [],
        "Leg_FR_Lower": [],
        "Paw_FR": [],
        "Leg_BL_Upper": [],
        "Leg_BL_Lower": [],
        "Paw_BL": [],
        "Leg_BR_Upper": [],
        "Leg_BR_Lower": [],
        "Paw_BR": []
    }
    
    def record_verts(vg_name, verts):
        for vert in verts:
            vg_vert_indices[vg_name].append(vert)

    # A. HINDQUARTERS / PELVIS (Y: 0.0 to 0.72, Z: 0.55 to 1.18)
    v_pelvis, _ = add_box(bm, -0.28, 0.28, 0.0, 0.72, 0.55, 1.18, "stone_dark")
    record_verts("Pelvis", v_pelvis)
    
    # Pelvis dorsal ridge
    v_p_ridge, _ = add_prism(bm, (-0.08, 0.72, 1.18), (0.0, 0.72, 1.28), (0.08, 0.72, 1.18),
                                  (-0.08, 0.05, 1.20), (0.0, 0.05, 1.34), (0.08, 0.05, 1.20), "cast_iron")
    record_verts("Pelvis", v_p_ridge)
    
    # Rear belly
    v_p_belly, _ = add_box(bm, -0.20, 0.20, 0.0, 0.55, 0.50, 0.72, "slate_light")
    record_verts("Pelvis", v_p_belly)

    # B. MAIN TORSO / CHEST (Y: -0.65 to 0.02, Z: 0.58 to 1.30)
    v_chest, _ = add_box(bm, -0.36, 0.36, -0.65, 0.02, 0.58, 1.30, "stone_dark")
    record_verts("Spine", v_chest)
    
    # Chest dorsal ridge
    v_c_ridge, _ = add_prism(bm, (-0.08, 0.05, 1.20), (0.0, 0.05, 1.34), (0.08, 0.05, 1.20),
                                  (-0.08, -0.62, 1.32), (0.0, -0.62, 1.44), (0.08, -0.62, 1.32), "cast_iron")
    record_verts("Spine", v_c_ridge)
    
    # Underbelly bib (snow pure)
    v_c_bib, _ = add_box(bm, -0.24, 0.24, -0.60, 0.0, 0.46, 0.78, "snow_pure")
    record_verts("Spine", v_c_bib)
    
    # Left & Right chest fur tufts
    v_tuft_l, _ = add_prism(bm, (-0.36, -0.15, 0.85), (-0.36, -0.45, 1.20), (-0.48, -0.25, 0.80),
                                 (-0.36, 0.05, 0.65), (-0.36, -0.25, 1.00), (-0.44, -0.05, 0.60), "slate_light")
    record_verts("Spine", v_tuft_l)
    
    v_tuft_r, _ = add_prism(bm, (0.36, -0.15, 0.85), (0.48, -0.25, 0.80), (0.36, -0.45, 1.20),
                                 (0.36, 0.05, 0.65), (0.44, -0.05, 0.60), (0.36, -0.25, 1.00), "slate_light")
    record_verts("Spine", v_tuft_r)

    # C. NECK (Y: -0.88 to -0.55, Z: 0.80 to 1.38)
    v_neck_main, _ = add_box(bm, -0.28, 0.28, -0.88, -0.55, 0.80, 1.38, "stone_dark")
    record_verts("Neck", v_neck_main)
    
    v_neck_throat, _ = add_box(bm, -0.20, 0.20, -0.85, -0.58, 0.72, 1.02, "snow_pure")
    record_verts("Neck", v_neck_throat)
    
    v_neck_scruff, _ = add_prism(bm, (-0.10, -0.55, 1.38), (0.0, -0.55, 1.48), (0.10, -0.55, 1.38),
                                      (-0.08, -0.85, 1.32), (0.0, -0.85, 1.42), (0.08, -0.85, 1.32), "cast_iron")
    record_verts("Neck", v_neck_scruff)

    # D. HEAD & SNOUT & EARS & EYES (Y: -1.65 to -0.85)
    # Cranium
    v_cranium, _ = add_box(bm, -0.25, 0.25, -1.18, -0.85, 0.90, 1.40, "stone_dark")
    record_verts("Head", v_cranium)
    
    # Cheek ruffs
    v_cheek_l, _ = add_prism(bm, (-0.25, -0.85, 1.15), (-0.25, -1.12, 0.88), (-0.36, -0.95, 0.98),
                                  (-0.25, -0.85, 1.35), (-0.25, -1.12, 1.15), (-0.32, -0.95, 1.25), "slate_light")
    record_verts("Head", v_cheek_l)
    
    v_cheek_r, _ = add_prism(bm, (0.25, -0.85, 1.15), (0.36, -0.95, 0.98), (0.25, -1.12, 0.88),
                                  (0.25, -0.85, 1.35), (0.32, -0.95, 1.25), (0.25, -1.12, 1.15), "slate_light")
    record_verts("Head", v_cheek_r)
    
    # Upper Snout / Muzzle
    v_snout, _ = add_box(bm, -0.15, 0.15, -1.55, -1.15, 0.92, 1.14, "stone_dark")
    record_verts("Head", v_snout)
    
    # Snout bridge crest
    v_snout_crest, _ = add_prism(bm, (-0.08, -1.15, 1.14), (0.0, -1.15, 1.20), (0.08, -1.15, 1.14),
                                      (-0.05, -1.54, 1.14), (0.0, -1.54, 1.18), (0.05, -1.54, 1.14), "cast_iron")
    record_verts("Head", v_snout_crest)
    
    # Nose (Black tip)
    v_nose, _ = add_prism(bm, (-0.06, -1.55, 0.98), (0.0, -1.55, 1.14), (0.06, -1.55, 0.98),
                              (-0.06, -1.63, 0.98), (0.0, -1.63, 1.10), (0.06, -1.63, 0.98), "pitch_black")
    record_verts("Head", v_nose)
    
    # Glowing Predator Eyes (Neon Red) - positioned prominently on upper face
    v_eye_l, _ = add_box(bm, -0.22, -0.12, -1.18, -1.12, 1.18, 1.28, "neon_red_glow")
    record_verts("Head", v_eye_l)
    
    v_eye_r, _ = add_box(bm, 0.12, 0.22, -1.18, -1.12, 1.18, 1.28, "neon_red_glow")
    record_verts("Head", v_eye_r)
    
    # Pointed Ears with soft pink interior
    v_ear_l, _ = add_pyramid(bm, (-0.24, -0.88, 1.40), (-0.24, -1.08, 1.40), (-0.08, -1.08, 1.40), (-0.08, -0.88, 1.40), (-0.16, -0.96, 1.78), "stone_dark")
    record_verts("Head", v_ear_l)
    v_ear_in_l, _ = add_tetra(bm, (-0.20, -1.00, 1.41), (-0.16, -0.95, 1.64), (-0.12, -1.00, 1.41), (-0.16, -1.04, 1.46), "pink_soft")
    record_verts("Head", v_ear_in_l)
    
    v_ear_r, _ = add_pyramid(bm, (0.08, -0.88, 1.40), (0.08, -1.08, 1.40), (0.24, -1.08, 1.40), (0.24, -0.88, 1.40), (0.16, -0.96, 1.78), "stone_dark")
    record_verts("Head", v_ear_r)
    v_ear_in_r, _ = add_tetra(bm, (0.12, -1.00, 1.41), (0.16, -0.95, 1.64), (0.20, -1.00, 1.41), (0.16, -1.04, 1.46), "pink_soft")
    record_verts("Head", v_ear_in_r)

    # E. LOWER JAW & FANGS & MOUTH (Jaw bone)
    v_jaw_base, _ = add_box(bm, -0.13, 0.13, -1.50, -1.05, 0.72, 0.88, "slate_light")
    record_verts("Jaw", v_jaw_base)
    
    # Mouth interior
    v_mouth, _ = add_box(bm, -0.11, 0.11, -1.45, -1.10, 0.88, 0.92, "crimson_dark")
    record_verts("Jaw", v_mouth)
    
    # 4 Sharp Fangs (snow pure)
    v_fang1, _ = add_tetra(bm, (-0.13, -1.42, 0.92), (-0.11, -1.49, 0.92), (-0.09, -1.42, 0.92), (-0.11, -1.45, 0.76), "snow_pure")
    record_verts("Head", v_fang1)
    v_fang2, _ = add_tetra(bm, (0.09, -1.42, 0.92), (0.11, -1.49, 0.92), (0.13, -1.42, 0.92), (0.11, -1.45, 0.76), "snow_pure")
    record_verts("Head", v_fang2)
    v_fang3, _ = add_tetra(bm, (-0.11, -1.38, 0.88), (-0.09, -1.45, 0.88), (-0.07, -1.38, 0.88), (-0.09, -1.41, 1.00), "snow_pure")
    record_verts("Jaw", v_fang3)
    v_fang4, _ = add_tetra(bm, (0.07, -1.38, 0.88), (0.09, -1.45, 0.88), (0.11, -1.38, 0.88), (0.09, -1.41, 1.00), "snow_pure")
    record_verts("Jaw", v_fang4)

    # F. TAIL (3 SEGMENTS)
    # Segment 1: Base (Y: 0.70 to 1.00, Z: 0.75 to 1.05)
    v_tail1, _ = add_box(bm, -0.12, 0.12, 0.70, 0.98, 0.76, 1.04, "stone_dark")
    record_verts("Tail_01", v_tail1)
    
    # Segment 2: Mid (Y: 0.98 to 1.30, Z: 0.58 to 0.90)
    v_tail2, _ = add_prism(bm, (-0.14, 0.98, 0.72), (0.0, 0.98, 1.06), (0.14, 0.98, 0.72),
                                (-0.11, 1.30, 0.58), (0.0, 1.30, 0.90), (0.11, 1.30, 0.58), "slate_light")
    record_verts("Tail_02", v_tail2)
    
    # Segment 3: Tip (Y: 1.30 to 1.62, Z: 0.45 to 0.78, Snow pure tip)
    v_tail3, _ = add_pyramid(bm, (-0.11, 1.30, 0.58), (-0.11, 1.30, 0.90), (0.11, 1.30, 0.90), (0.11, 1.30, 0.58), (0.0, 1.62, 0.68), "snow_pure")
    record_verts("Tail_03", v_tail3)

    # G. FRONT LEGS (FL & FR)
    # FL Upper Leg (Shoulder/Arm: Z 0.50 to 0.90)
    v_fl_up, _ = add_box(bm, -0.34, -0.18, -0.52, -0.26, 0.50, 0.90, "stone_dark")
    record_verts("Leg_FL_Upper", v_fl_up)
    # FL Lower Leg (Forearm: Z 0.14 to 0.50)
    v_fl_low, _ = add_box(bm, -0.32, -0.20, -0.48, -0.30, 0.14, 0.50, "slate_light")
    record_verts("Leg_FL_Lower", v_fl_low)
    # FL Paw & Claws (Z 0.0 to 0.14)
    v_fl_paw, _ = add_prism(bm, (-0.33, -0.28, 0.0), (-0.26, -0.28, 0.14), (-0.19, -0.28, 0.0),
                                 (-0.33, -0.56, 0.0), (-0.26, -0.56, 0.12), (-0.19, -0.56, 0.0), "cast_iron")
    record_verts("Paw_FL", v_fl_paw)

    # FR Upper Leg (Shoulder/Arm: Z 0.50 to 0.90)
    v_fr_up, _ = add_box(bm, 0.18, 0.34, -0.52, -0.26, 0.50, 0.90, "stone_dark")
    record_verts("Leg_FR_Upper", v_fr_up)
    # FR Lower Leg (Forearm: Z 0.14 to 0.50)
    v_fr_low, _ = add_box(bm, 0.20, 0.32, -0.48, -0.30, 0.14, 0.50, "slate_light")
    record_verts("Leg_FR_Lower", v_fr_low)
    # FR Paw & Claws (Z 0.0 to 0.14)
    v_fr_paw, _ = add_prism(bm, (0.19, -0.28, 0.0), (0.26, -0.28, 0.14), (0.33, -0.28, 0.0),
                                 (0.19, -0.56, 0.0), (0.26, -0.56, 0.12), (0.33, -0.56, 0.0), "cast_iron")
    record_verts("Paw_FR", v_fr_paw)

    # H. BACK LEGS (BL & BR)
    # BL Upper Leg (Thigh: Z 0.48 to 0.88)
    v_bl_up, _ = add_box(bm, -0.33, -0.17, 0.35, 0.65, 0.48, 0.88, "stone_dark")
    record_verts("Leg_BL_Upper", v_bl_up)
    # BL Lower Leg (Hock: Z 0.14 to 0.48)
    v_bl_low, _ = add_box(bm, -0.31, -0.19, 0.42, 0.60, 0.14, 0.48, "slate_light")
    record_verts("Leg_BL_Lower", v_bl_low)
    # BL Paw & Claws (Z 0.0 to 0.14)
    v_bl_paw, _ = add_prism(bm, (-0.32, 0.62, 0.0), (-0.25, 0.62, 0.14), (-0.18, 0.62, 0.0),
                                 (-0.32, 0.36, 0.0), (-0.25, 0.36, 0.12), (-0.18, 0.36, 0.0), "cast_iron")
    record_verts("Paw_BL", v_bl_paw)

    # BR Upper Leg (Thigh: Z 0.48 to 0.88)
    v_br_up, _ = add_box(bm, 0.17, 0.33, 0.35, 0.65, 0.48, 0.88, "stone_dark")
    record_verts("Leg_BR_Upper", v_br_up)
    # BR Lower Leg (Hock: Z 0.14 to 0.48)
    v_br_low, _ = add_box(bm, 0.19, 0.31, 0.42, 0.60, 0.14, 0.48, "slate_light")
    record_verts("Leg_BR_Lower", v_br_low)
    # BR Paw & Claws (Z 0.0 to 0.14)
    v_br_paw, _ = add_prism(bm, (0.18, 0.62, 0.0), (0.25, 0.62, 0.14), (0.32, 0.62, 0.0),
                                 (0.18, 0.36, 0.0), (0.25, 0.36, 0.12), (0.32, 0.36, 0.0), "cast_iron")
    record_verts("Paw_BR", v_br_paw)

    bm.normal_update()
    bm.verts.index_update()
    bm.verts.ensure_lookup_table()
    vg_indices_map = {}
    for vg_name, vert_list in vg_vert_indices.items():
        vg_indices_map[vg_name] = [v.index for v in vert_list if v.index >= 0]
        
    bm.to_mesh(mesh)
    bm.free()
    
    wolf_mesh_obj = bpy.data.objects.new("Wolf_Mesh", mesh)
    bpy.context.collection.objects.link(wolf_mesh_obj)
    
    mat = get_or_create_palette_mat()
    wolf_mesh_obj.data.materials.append(mat)
    if wolf_mesh_obj.data.uv_layers.active:
        wolf_mesh_obj.data.uv_layers.active.name = "UVMap"
        
    bpy.context.view_layer.objects.active = wolf_mesh_obj
    bpy.ops.object.shade_flat()

    # -------------------------------------------------------------
    # 2. CREATE SKELETON / ARMATURE RIG
    # -------------------------------------------------------------
    arm_data = bpy.data.armatures.new("WolfArmature")
    arm_obj = bpy.data.objects.new("Wolf", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm_data.edit_bones
    
    # Root
    root = eb.new("Root")
    root.head = (0, 0, 0)
    root.tail = (0, 0, 0.25)
    
    # Pelvis
    pelvis = eb.new("Pelvis")
    pelvis.head = (0, 0.15, 0.85)
    pelvis.tail = (0, 0.65, 0.85)
    pelvis.parent = root
    
    # Spine (Chest)
    spine = eb.new("Spine")
    spine.head = (0, 0.15, 0.85)
    spine.tail = (0, -0.55, 0.95)
    spine.parent = pelvis
    
    # Neck
    neck = eb.new("Neck")
    neck.head = (0, -0.55, 0.95)
    neck.tail = (0, -0.88, 1.15)
    neck.parent = spine
    
    # Head
    head = eb.new("Head")
    head.head = (0, -0.88, 1.15)
    head.tail = (0, -1.60, 1.05)
    head.parent = neck
    
    # Jaw
    jaw = eb.new("Jaw")
    jaw.head = (0, -0.98, 0.88)
    jaw.tail = (0, -1.48, 0.78)
    jaw.parent = head
    
    # Tail 1, 2, 3
    tail1 = eb.new("Tail_01")
    tail1.head = (0, 0.68, 0.88)
    tail1.tail = (0, 0.98, 0.82)
    tail1.parent = pelvis
    
    tail2 = eb.new("Tail_02")
    tail2.head = (0, 0.98, 0.82)
    tail2.tail = (0, 1.28, 0.68)
    tail2.parent = tail1
    
    tail3 = eb.new("Tail_03")
    tail3.head = (0, 1.28, 0.68)
    tail3.tail = (0, 1.58, 0.52)
    tail3.parent = tail2
    
    # Front-Left Leg
    fl_up = eb.new("Leg_FL_Upper")
    fl_up.head = (-0.26, -0.38, 0.85)
    fl_up.tail = (-0.26, -0.38, 0.50)
    fl_up.parent = spine
    
    fl_low = eb.new("Leg_FL_Lower")
    fl_low.head = (-0.26, -0.38, 0.50)
    fl_low.tail = (-0.26, -0.38, 0.14)
    fl_low.parent = fl_up
    
    fl_paw = eb.new("Paw_FL")
    fl_paw.head = (-0.26, -0.38, 0.14)
    fl_paw.tail = (-0.26, -0.54, 0.0)
    fl_paw.parent = fl_low
    
    # Front-Right Leg
    fr_up = eb.new("Leg_FR_Upper")
    fr_up.head = (0.26, -0.38, 0.85)
    fr_up.tail = (0.26, -0.38, 0.50)
    fr_up.parent = spine
    
    fr_low = eb.new("Leg_FR_Lower")
    fr_low.head = (0.26, -0.38, 0.50)
    fr_low.tail = (0.26, -0.38, 0.14)
    fr_low.parent = fr_up
    
    fr_paw = eb.new("Paw_FR")
    fr_paw.head = (0.26, -0.38, 0.14)
    fr_paw.tail = (0.26, -0.54, 0.0)
    fr_paw.parent = fr_low

    # Back-Left Leg
    bl_up = eb.new("Leg_BL_Upper")
    bl_up.head = (-0.25, 0.52, 0.82)
    bl_up.tail = (-0.25, 0.58, 0.48)
    bl_up.parent = pelvis
    
    bl_low = eb.new("Leg_BL_Lower")
    bl_low.head = (-0.25, 0.58, 0.48)
    bl_low.tail = (-0.25, 0.50, 0.14)
    bl_low.parent = bl_up
    
    bl_paw = eb.new("Paw_BL")
    bl_paw.head = (-0.25, 0.50, 0.14)
    bl_paw.tail = (-0.25, 0.38, 0.0)
    bl_paw.parent = bl_low

    # Back-Right Leg
    br_up = eb.new("Leg_BR_Upper")
    br_up.head = (0.25, 0.52, 0.82)
    br_up.tail = (0.25, 0.58, 0.48)
    br_up.parent = pelvis
    
    br_low = eb.new("Leg_BR_Lower")
    br_low.head = (0.25, 0.58, 0.48)
    br_low.tail = (0.25, 0.50, 0.14)
    br_low.parent = br_up
    
    br_paw = eb.new("Paw_BR")
    br_paw.head = (0.25, 0.50, 0.14)
    br_paw.tail = (0.25, 0.38, 0.0)
    br_paw.parent = br_low

    bpy.ops.object.mode_set(mode='OBJECT')

    # -------------------------------------------------------------
    # 3. ASSIGN VERTEX GROUPS & PARENT MESH TO ARMATURE
    # -------------------------------------------------------------
    for vg_name, indices in vg_indices_map.items():
        if not indices:
            continue
        vg = wolf_mesh_obj.vertex_groups.get(vg_name)
        if not vg:
            vg = wolf_mesh_obj.vertex_groups.new(name=vg_name)
        vg.add(indices, 1.0, 'REPLACE')

    wolf_mesh_obj.parent = arm_obj
    mod = wolf_mesh_obj.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = arm_obj

    # -------------------------------------------------------------
    # 4. CREATE ANIMATIONS
    # -------------------------------------------------------------
    if not arm_obj.animation_data:
        arm_obj.animation_data_create()
        
    def set_bone_rot(pb_name, rx_deg, ry_deg, rz_deg, frame_idx):
        pb = arm_obj.pose.bones.get(pb_name)
        if pb:
            pb.rotation_mode = 'XYZ'
            pb.rotation_euler = (math.radians(rx_deg), math.radians(ry_deg), math.radians(rz_deg))
            pb.keyframe_insert(data_path="rotation_euler", frame=frame_idx)
            
    def set_bone_loc(pb_name, lx, ly, lz, frame_idx):
        pb = arm_obj.pose.bones.get(pb_name)
        if pb:
            pb.location = (lx, ly, lz)
            pb.keyframe_insert(data_path="location", frame=frame_idx)

    # -------------------------------------------------------------
    # ANIMATION 1: "Wolf_Walk" / "Walk" (24 Frames Trot/Walk Cycle)
    # -------------------------------------------------------------
    act_walk = bpy.data.actions.new(name="Wolf_Walk")
    arm_obj.animation_data.action = act_walk
    
    for f, (pz, s_roll, s_pitch) in [
        (1,  (0.00,  0.0,  0.0)),
        (7,  (-0.03,  2.0,  3.0)),
        (13, (0.00,  0.0, -1.0)),
        (19, (-0.03, -2.0,  3.0)),
        (25, (0.00,  0.0,  0.0)),
    ]:
        set_bone_loc("Pelvis", 0, 0, pz, f)
        set_bone_rot("Pelvis", s_pitch, s_roll, -s_roll*0.8, f)
        set_bone_rot("Spine", -s_pitch*0.5, -s_roll*0.7, s_roll*0.6, f)
        
    for f, (np, hp) in [
        (1,  (0.0,  0.0)),
        (7,  (-2.0,  3.0)),
        (13, (1.0, -1.0)),
        (19, (-2.0,  3.0)),
        (25, (0.0,  0.0)),
    ]:
        set_bone_rot("Neck", np, 0, 0, f)
        set_bone_rot("Head", hp, 0, 0, f)
        set_bone_rot("Jaw", 2.0 if (f in [7, 19]) else 0.0, 0, 0, f)

    for f, (t1_y, t2_y, t3_y) in [
        (1,  (0.0,   0.0,   0.0)),
        (7,  (12.0,  18.0,  24.0)),
        (13, (0.0,   0.0,   0.0)),
        (19, (-12.0, -18.0, -24.0)),
        (25, (0.0,   0.0,   0.0)),
    ]:
        set_bone_rot("Tail_01", -5.0, 0, t1_y, f)
        set_bone_rot("Tail_02", -3.0, 0, t2_y, f)
        set_bone_rot("Tail_03", 2.0,  0, t3_y, f)

    for f, (up_x, low_x, paw_x) in [
        (1,  (22.0,   -8.0,  -10.0)),
        (7,  (5.0,    -2.0,    0.0)),
        (13, (-24.0,  -12.0,  15.0)),
        (19, (-2.0,   35.0,  -20.0)),
        (25, (22.0,   -8.0,  -10.0)),
    ]:
        set_bone_rot("Leg_FL_Upper", up_x, 0, 0, f)
        set_bone_rot("Leg_FL_Lower", low_x, 0, 0, f)
        set_bone_rot("Paw_FL", paw_x, 0, 0, f)

    for f, (up_x, low_x, paw_x) in [
        (1,  (-24.0,  -12.0,  15.0)),
        (7,  (-2.0,   35.0,  -20.0)),
        (13, (22.0,   -8.0,  -10.0)),
        (19, (5.0,    -2.0,    0.0)),
        (25, (-24.0,  -12.0,  15.0)),
    ]:
        set_bone_rot("Leg_FR_Upper", up_x, 0, 0, f)
        set_bone_rot("Leg_FR_Lower", low_x, 0, 0, f)
        set_bone_rot("Paw_FR", paw_x, 0, 0, f)

    for f, (up_x, low_x, paw_x) in [
        (1,  (18.0,   20.0,  -12.0)),
        (7,  (0.0,     5.0,    0.0)),
        (13, (-22.0, -18.0,   18.0)),
        (19, (5.0,    30.0,  -15.0)),
        (25, (18.0,   20.0,  -12.0)),
    ]:
        set_bone_rot("Leg_BR_Upper", up_x, 0, 0, f)
        set_bone_rot("Leg_BR_Lower", low_x, 0, 0, f)
        set_bone_rot("Paw_BR", paw_x, 0, 0, f)

    for f, (up_x, low_x, paw_x) in [
        (1,  (-22.0, -18.0,   18.0)),
        (7,  (5.0,    30.0,  -15.0)),
        (13, (18.0,   20.0,  -12.0)),
        (19, (0.0,     5.0,    0.0)),
        (25, (-22.0, -18.0,   18.0)),
    ]:
        set_bone_rot("Leg_BL_Upper", up_x, 0, 0, f)
        set_bone_rot("Leg_BL_Lower", low_x, 0, 0, f)
        set_bone_rot("Paw_BL", paw_x, 0, 0, f)

    track_walk = arm_obj.animation_data.nla_tracks.new()
    track_walk.name = "Walk"
    strip_walk = track_walk.strips.new("Walk", 1, act_walk)
    strip_walk.action = act_walk

    # -------------------------------------------------------------
    # ANIMATION 2: "Wolf_Sleep" / "Sleep" (60 Frames Curled Sleep Idle)
    # -------------------------------------------------------------
    act_sleep = bpy.data.actions.new(name="Wolf_Sleep")
    arm_obj.animation_data.action = act_sleep

    for f, breathe_z, breathe_pitch in [
        (1,   -0.48,  0.0),
        (30,  -0.45,  1.5),
        (60,  -0.48,  0.0),
    ]:
        set_bone_loc("Pelvis", 0.05, 0.0, breathe_z, f)
        set_bone_rot("Pelvis", -5.0 + breathe_pitch, -8.0, 15.0, f)
        set_bone_rot("Spine", 4.0 + breathe_pitch*1.2, 5.0, -12.0, f)
        set_bone_rot("Neck", -18.0 + breathe_pitch*0.5, 0.0, -25.0, f)
        set_bone_rot("Head", -15.0, 12.0, -18.0, f)
        set_bone_rot("Jaw", -4.0, 0.0, 0.0, f)

        set_bone_rot("Tail_01", -25.0, 0.0, -45.0, f)
        set_bone_rot("Tail_02", -10.0, 0.0, -55.0, f)
        set_bone_rot("Tail_03", 5.0 + breathe_pitch, 0.0, -40.0, f)

        set_bone_rot("Leg_FL_Upper", 68.0, -15.0, 10.0, f)
        set_bone_rot("Leg_FL_Lower", -110.0, 0.0, 0.0, f)
        set_bone_rot("Paw_FL", 45.0, 0.0, 0.0, f)

        set_bone_rot("Leg_FR_Upper", 62.0, 18.0, -12.0, f)
        set_bone_rot("Leg_FR_Lower", -105.0, 0.0, 0.0, f)
        set_bone_rot("Paw_FR", 42.0, 0.0, 0.0, f)

        set_bone_rot("Leg_BL_Upper", 78.0, -22.0, 15.0, f)
        set_bone_rot("Leg_BL_Lower", -118.0, 0.0, 0.0, f)
        set_bone_rot("Paw_BL", 40.0, 0.0, 0.0, f)

        set_bone_rot("Leg_BR_Upper", 72.0, 20.0, -15.0, f)
        set_bone_rot("Leg_BR_Lower", -112.0, 0.0, 0.0, f)
        set_bone_rot("Paw_BR", 38.0, 0.0, 0.0, f)

    track_sleep = arm_obj.animation_data.nla_tracks.new()
    track_sleep.name = "Sleep"
    strip_sleep = track_sleep.strips.new("Sleep", 1, act_sleep)
    strip_sleep.action = act_sleep

    # -------------------------------------------------------------
    # 5. ENVIRONMENT / LIGHTS / CAMERA
    # -------------------------------------------------------------
    # Add a subtle ground snow circle
    bm_ground = bmesh.new()
    bmesh.ops.create_circle(bm_ground, cap_ends=True, radius=3.5, segments=16)
    m_ground = bpy.data.meshes.new("GroundMesh")
    bm_ground.to_mesh(m_ground)
    bm_ground.free()
    ground_obj = bpy.data.objects.new("SnowGround", m_ground)
    ground_obj.location = (0, 0, -0.01)
    bpy.context.collection.objects.link(ground_obj)
    ground_obj.data.materials.append(mat)
    # Assign snow_ambient UV to ground
    if ground_obj.data.uv_layers.active:
        u = COLOR_UV_MAP.get("snow_ambient", {}).get("u", 0.1875)
        v = COLOR_UV_MAP.get("snow_ambient", {}).get("v", 0.9375)
        for loop in ground_obj.data.uv_layers.active.data:
            loop.uv = (u, v)

    # Lighting
    sun_data = bpy.data.lights.new(name="SunLight", type='SUN')
    sun_data.energy = 3.5
    sun_data.color = (1.0, 0.97, 0.92)
    sun_obj = bpy.data.objects.new(name="Sun", object_data=sun_data)
    sun_obj.location = (4.0, -5.0, 6.0)
    sun_obj.rotation_euler = (math.radians(52), math.radians(12), math.radians(-38))
    bpy.context.collection.objects.link(sun_obj)

    fill_data = bpy.data.lights.new(name="FillLight", type='SUN')
    fill_data.energy = 1.4
    fill_data.color = (0.70, 0.85, 1.0)
    fill_obj = bpy.data.objects.new(name="Fill", object_data=fill_data)
    fill_obj.location = (-5.0, 4.0, 4.0)
    fill_obj.rotation_euler = (math.radians(128), math.radians(18), math.radians(140))
    bpy.context.collection.objects.link(fill_obj)

    # Camera with good distance & framing
    cam_data = bpy.data.cameras.new(name="MainCam")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new(name="Camera", object_data=cam_data)
    cam_obj.location = (-3.8, -4.5, 2.6)
    cam_obj.rotation_euler = (math.radians(68), 0, math.radians(-40))
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Save .blend files
    blend_path_main = os.path.join(MODELS_DIR, "wolf.blend")
    blend_path_monsters = os.path.join(MONSTERS_DIR, "wolf.blend")
    blend_path_mobs = os.path.join(MOBS_DIR, "wolf.blend")
    
    bpy.ops.wm.save_as_mainfile(filepath=blend_path_main)
    import shutil
    shutil.copy2(blend_path_main, blend_path_monsters)
    shutil.copy2(blend_path_main, blend_path_mobs)

    # -------------------------------------------------------------
    # 6. EXPORT RIGGED ANIMATED FBX
    # -------------------------------------------------------------
    bpy.ops.object.select_all(action='DESELECT')
    arm_obj.select_set(True)
    wolf_mesh_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj

    fbx_main = os.path.join(MODELS_DIR, "wolf.fbx")
    fbx_monsters = os.path.join(MONSTERS_DIR, "wolf.fbx")
    fbx_mobs = os.path.join(MOBS_DIR, "wolf.fbx")
    
    for fbx_path in [fbx_main, fbx_monsters, fbx_mobs]:
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            apply_scale_options='FBX_SCALE_ALL',
            bake_space_transform=True,
            add_leaf_bones=False,
            primary_bone_axis='Y',
            secondary_bone_axis='X',
            bake_anim=True,
            bake_anim_use_all_actions=True,
            bake_anim_use_nla_strips=True,
            bake_anim_step=1.0,
            bake_anim_simplify_factor=0.0
        )
        print(f"[EXPORT] Rigged Animated FBX saved to: {fbx_path}")

    # Fallback static OBJ
    obj_main = os.path.join(MODELS_DIR, "wolf.obj")
    bpy.ops.wm.obj_export(
        filepath=obj_main,
        export_selected_objects=True,
        forward_axis='NEGATIVE_Z',
        up_axis='Y',
        apply_modifiers=True
    )
    shutil.copy2(obj_main, os.path.join(MONSTERS_DIR, "wolf.obj"))
    shutil.copy2(obj_main, os.path.join(MOBS_DIR, "wolf.obj"))

    tri_count = sum(len(p.vertices) - 2 for p in wolf_mesh_obj.data.polygons)
    print(f"[SUCCESS] Wolf built! Tris: {tri_count} | Bones: {len(arm_data.bones)} | Actions: Walk, Sleep")
    return tri_count

tri_count = build_wolf_asset()
print(f"COMPLETED_WOLF_TRIS_{tri_count}")
"""

def send_blender_command(command_type, params=None, timeout=30.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    s.connect((HOST, PORT))
    
    cmd = {
        "type": command_type,
        "params": params or {}
    }
    
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
                return res
            except json.JSONDecodeError:
                continue
        except socket.timeout:
            break
            
    s.close()
    if chunks:
        data = b"".join(chunks)
        try:
            return json.loads(data.decode('utf-8'))
        except:
            return {"status": "error", "message": "Incomplete response: " + data.decode('utf-8', errors='ignore')}
    return {"status": "error", "message": "No data received"}

def render_pose_views():
    artifact_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\091bceeb-504a-4a50-a7df-e1a798f09f40"
    walk_img = os.path.join(artifact_dir, "wolf_walk_pose.png")
    sleep_img = os.path.join(artifact_dir, "wolf_sleep_pose.png")
    front_img = os.path.join(artifact_dir, "wolf_front_view.png")

    render_code = f"""
import bpy
import math

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

arm = bpy.data.objects.get("Wolf")
cam = bpy.data.objects.get("Camera")
act_walk = bpy.data.actions.get("Wolf_Walk")
act_sleep = bpy.data.actions.get("Wolf_Sleep")

# 1. Walk Pose Render
if arm and act_walk:
    for t in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(t)
    arm.animation_data.use_nla = False
    arm.animation_data.action = act_walk
    scene.frame_set(7)
    cam.location = (-3.8, -4.5, 2.6)
    cam.rotation_euler = (math.radians(68), 0, math.radians(-40))
    scene.render.filepath = r"{walk_img}"
    bpy.ops.render.render(write_still=True)
    print("Rendered Walk Pose")

# 2. Sleep Pose Render
if arm and act_sleep:
    for t in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(t)
    arm.animation_data.use_nla = False
    arm.animation_data.action = act_sleep
    scene.frame_set(30)
    cam.location = (-3.2, -3.8, 2.8)
    cam.rotation_euler = (math.radians(62), 0, math.radians(-40))
    scene.render.filepath = r"{sleep_img}"
    bpy.ops.render.render(write_still=True)
    print("Rendered Sleep Pose")

# 3. Front Close-up View
if arm and act_walk:
    for t in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(t)
    arm.animation_data.use_nla = False
    arm.animation_data.action = act_walk
    scene.frame_set(1)
    cam.location = (0.0, -3.5, 1.4)
    cam.rotation_euler = (math.radians(82), 0, 0)
    scene.render.filepath = r"{front_img}"
    bpy.ops.render.render(write_still=True)
    print("Rendered Front Close-up View")

# Reset default to Walk
if arm and act_walk:
    arm.animation_data.action = act_walk
    scene.frame_set(1)
    cam.location = (-3.8, -4.5, 2.6)
    cam.rotation_euler = (math.radians(68), 0, math.radians(-40))
"""
    res = send_blender_command("execute_code", {"code": render_code})
    print("[Render Views Response]:", res)

def main():
    print("[Blender 5.0] Connecting to Blender on port 9876...")
    res = send_blender_command("execute_code", {"code": BLENDER_CODE})
    print("Blender Execution Output:")
    print(json.dumps(res, indent=2))
    
    print("\n[Rendering] Capturing Walk, Sleep and Front view renders...")
    render_pose_views()
    
    print("\n[SUCCESS] Completed wolf modeling, rigging, walk & sleep animations, and renders!")

if __name__ == "__main__":
    main()
