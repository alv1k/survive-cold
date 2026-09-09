"""
    tools/generate_all_buildings.py
    Generates and renders 4 thematic architectural color variations of the building:
    1. PlayerHouse (Уютный медовый сруб)
    2. FoodShop (Продуктовая лавка провизии)
    3. ClothingShop (Магазин тёплой одежды)
    4. HunterCabin (Таёжная охотничья заимка)
"""

import bpy
import bmesh
import mathutils
from mathutils import Matrix, Euler, Vector
import math
import os
import shutil
import json

ARTIFACTS_DIR = r"C:\Users\pc1\.gemini\antigravity-ide\brain\d766dd16-21c3-45ee-9fb6-b500cd9314ac"
MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
SOURCES_DIR = os.path.join(MODELS_DIR, "sources")
TEXTURES_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures"
PALETTE_PATH = os.path.join(TEXTURES_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

for d in [ARTIFACTS_DIR, MODELS_DIR, SOURCES_DIR]:
    os.makedirs(d, exist_ok=True)

COLOR_UV_MAP = {}
if os.path.exists(UV_MAP_PATH):
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
    scene.render.engine = 'BLENDER_EEVEE'

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
    uv_lay = bm.loops.layers.uv.verify()
    for f in faces:
        for loop in f.loops:
            loop[uv_lay].uv = (u, v)

def add_box(bm, center, size, color_name):
    hx, hy, hz = size[0] / 2.0, size[1] / 2.0, size[2] / 2.0
    cx, cy, cz = center[0], center[1], center[2]
    
    verts = [
        bm.verts.new((cx - hx, cy - hy, cz - hz)),
        bm.verts.new((cx + hx, cy - hy, cz - hz)),
        bm.verts.new((cx + hx, cy + hy, cz - hz)),
        bm.verts.new((cx - hx, cy + hy, cz - hz)),
        bm.verts.new((cx - hx, cy - hy, cz + hz)),
        bm.verts.new((cx + hx, cy - hy, cz + hz)),
        bm.verts.new((cx + hx, cy + hy, cz + hz)),
        bm.verts.new((cx - hx, cy + hy, cz + hz)),
    ]
    
    face_indices = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
        (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0),
    ]
    
    created_faces = []
    for f_idx in face_indices:
        f = bm.faces.new([verts[i] for i in f_idx])
        created_faces.append(f)
    
    set_bmesh_uv(bm, created_faces, color_name)
    return created_faces

def add_sloped_slab(bm, x_min, x_max, y_start, y_end, z_start, z_end, thickness, offset_n, color_name):
    dy = y_end - y_start
    dz = z_end - z_start
    hyp = math.sqrt(dy * dy + dz * dz)
    
    ty = dy / hyp
    tz = dz / hyp
    ny = -tz
    nz = ty
    
    p0 = (x_min, y_start + ny * offset_n, z_start + nz * offset_n)
    p1 = (x_max, y_start + ny * offset_n, z_start + nz * offset_n)
    p2 = (x_max, y_end + ny * offset_n, z_end + nz * offset_n)
    p3 = (x_min, y_end + ny * offset_n, z_end + nz * offset_n)
    
    top_off = offset_n + thickness
    p4 = (x_min, y_start + ny * top_off, z_start + nz * top_off)
    p5 = (x_max, y_start + ny * top_off, z_start + nz * top_off)
    p6 = (x_max, y_end + ny * top_off, z_end + nz * top_off)
    p7 = (x_min, y_end + ny * top_off, z_end + nz * top_off)
    
    verts = [bm.verts.new(p) for p in [p0, p1, p2, p3, p4, p5, p6, p7]]
    face_indices = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
        (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0),
    ]
    faces = [bm.faces.new([verts[i] for i in idx]) for idx in face_indices]
    set_bmesh_uv(bm, faces, color_name)
    return faces

def add_prism_x(bm, pt_a, pt_b, pt_c, x_min, x_max, color_name):
    v_l = [bm.verts.new((x_min, p[0], p[1])) for p in [pt_a, pt_b, pt_c]]
    v_r = [bm.verts.new((x_max, p[0], p[1])) for p in [pt_a, pt_b, pt_c]]
    faces = [
        bm.faces.new([v_l[0], v_l[1], v_l[2]]),
        bm.faces.new([v_r[2], v_r[1], v_r[0]]),
        bm.faces.new([v_l[0], v_r[0], v_r[1], v_l[1]]),
        bm.faces.new([v_l[1], v_r[1], v_r[2], v_l[2]]),
        bm.faces.new([v_l[2], v_r[2], v_r[0], v_l[0]]),
    ]
    set_bmesh_uv(bm, faces, color_name)
    return faces

def add_cylinder(bm, center, radius, height, segments=12, color_name="cast_iron"):
    cx, cy, cz = center
    hz = height / 2.0
    bot_verts = []
    top_verts = []
    
    for i in range(segments):
        angle = (2.0 * math.pi * i) / segments
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        bot_verts.append(bm.verts.new((x, y, cz - hz)))
        top_verts.append(bm.verts.new((x, y, cz + hz)))
        
    created_faces = []
    for i in range(segments):
        ni = (i + 1) % segments
        f = bm.faces.new([bot_verts[i], top_verts[i], top_verts[ni], bot_verts[ni]])
        created_faces.append(f)
        
    created_faces.append(bm.faces.new(bot_verts[::-1]))
    created_faces.append(bm.faces.new(top_verts))
    
    set_bmesh_uv(bm, created_faces, color_name)
    return created_faces

W_X = 16.0
D_Y = 14.0
H_FRONT = 8.6
H_BACK = 6.4
FLOOR_Z = 0.5
Y_EAVE_FRONT = -8.8
Z_EAVE_FRONT = 9.1
Y_EAVE_BACK = 8.8
Z_EAVE_BACK = 6.3

def build_house_model(theme):
    t_found_stone1 = theme.get("found_stone1", "stone_dark")
    t_found_stone2 = theme.get("found_stone2", "stone_slate")
    t_found_rim = theme.get("found_rim", "wood_bark")
    t_found_joist = theme.get("found_joist", "wood_cedar")
    t_floor_planks = theme.get("floor_planks", ["wood_pine", "wood_honey_oak", "wood_pine", "wood_honey_oak", "wood_birch"])
    t_wall_a = theme.get("wall_a", "wood_honey_oak")
    t_wall_b = theme.get("wall_b", "wood_cedar")
    t_trims = theme.get("trims", "wood_cedar")
    t_sill = theme.get("sill", "wood_walnut")
    t_crossbars = theme.get("crossbars", "wood_pine")
    t_glass = theme.get("glass", "ice_light")
    t_rafters = theme.get("rafters", "wood_cedar")
    t_roof_deck = theme.get("roof_deck", "wood_walnut")
    t_roof_battens = theme.get("roof_battens", "wood_cedar")
    t_chim_base = theme.get("chim_base", "stone_dark")
    t_chim_flashing = theme.get("chim_flashing", "stone_slate")
    t_chim_pipe = theme.get("chim_pipe", "cast_iron")
    t_chim_band = theme.get("chim_band", "gunmetal")
    
    mat = get_or_create_palette_mat()
    root = bpy.data.objects.new(theme["name"], None)
    bpy.context.collection.objects.link(root)
    
    # 1. Foundation
    def _fn_found(bm):
        corners = [(-8.2, -7.2), (8.2, -7.2), (-8.2, 7.2), (8.2, 7.2), (0.0, -7.2), (0.0, 7.2)]
        for cx, cy in corners:
            add_box(bm, (cx, cy, 0.25), (1.6, 1.6, 0.5), t_found_stone1)
            add_box(bm, (cx, cy, 0.05), (1.8, 1.8, 0.15), t_found_stone2)
        add_box(bm, (0.0, -7.0, 0.35), (16.6, 0.85, 0.5), t_found_rim)
        add_box(bm, (0.0, 7.0, 0.35), (16.6, 0.85, 0.5), t_found_rim)
        add_box(bm, (-8.0, 0.0, 0.35), (0.85, 14.0, 0.5), t_found_rim)
        add_box(bm, (8.0, 0.0, 0.35), (0.85, 14.0, 0.5), t_found_rim)
        add_box(bm, (0.0, 0.0, 0.3), (0.6, 14.0, 0.4), t_found_joist)
    
    # 2. Floor (adjusted with user's scale: D_Y * 1.045 = ~14.63)
    def _fn_floor(bm):
        num_planks = 14
        plank_width = (W_X - 1.4) / num_planks
        floor_len = (D_Y - 1.4) * 1.045
        for i in range(num_planks):
            px = - (W_X - 1.4)/2.0 + (i + 0.5) * plank_width
            col = t_floor_planks[i % len(t_floor_planks)]
            jitter_z = (i % 3) * 0.015
            add_box(bm, (px, 0.0, FLOOR_Z - 0.05 + jitter_z), (plank_width - 0.04, floor_len, 0.12), col)
            
    # 3. Walls
    def _fn_walls(bm):
        beam_h = 0.55
        beam_thickness = 0.68
        z_cur = FLOOR_Z + beam_h / 2.0
        layer = 0
        while z_cur < H_BACK:
            col = t_wall_a if layer % 2 == 0 else t_wall_b
            add_box(bm, (0.0, 7.0, z_cur), (W_X + 1.4, beam_thickness, beam_h - 0.02), col)
            z_cur += beam_h
            layer += 1
            
        z_cur = FLOOR_Z + beam_h / 2.0
        layer = 0
        while z_cur < H_FRONT:
            col = t_wall_a if layer % 2 == 0 else t_wall_b
            if z_cur < 2.4:
                add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
                add_box(bm, (3.5, -7.0, z_cur), (9.2, beam_thickness, beam_h - 0.02), col)
            elif z_cur < 5.4:
                add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
                add_box(bm, (0.7, -7.0, z_cur), (3.4, beam_thickness, beam_h - 0.02), col)
                add_box(bm, (6.8, -7.0, z_cur), (2.4, beam_thickness, beam_h - 0.02), col)
            elif z_cur < 5.8:
                add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
                add_box(bm, (3.5, -7.0, z_cur), (9.2, beam_thickness, beam_h - 0.02), col)
            else:
                add_box(bm, (0.0, -7.0, z_cur), (W_X + 1.4, beam_thickness, beam_h - 0.02), col)
            z_cur += beam_h
            layer += 1
            
        z_cur = FLOOR_Z + beam_h / 2.0
        layer = 0
        while z_cur < H_BACK:
            col = t_wall_a if layer % 2 == 0 else t_wall_b
            if z_cur >= 2.4 and z_cur <= 5.4:
                add_box(bm, (-8.0, -4.3, z_cur), (beam_thickness, 5.4, beam_h - 0.02), col)
                add_box(bm, (-8.0, 4.3, z_cur), (beam_thickness, 5.4, beam_h - 0.02), col)
            else:
                add_box(bm, (-8.0, 0.0, z_cur), (beam_thickness, D_Y + 1.4, beam_h - 0.02), col)
            z_cur += beam_h
            layer += 1
        add_prism_x(bm, (-7.0, H_FRONT), (7.0, H_BACK), (-7.0, H_BACK), -8.0 - beam_thickness/2.0, -8.0 + beam_thickness/2.0, t_wall_b)
        
        z_cur = FLOOR_Z + beam_h / 2.0
        layer = 0
        while z_cur < H_BACK:
            col = t_wall_a if layer % 2 == 0 else t_wall_b
            add_box(bm, (8.0, 0.0, z_cur), (beam_thickness, D_Y + 1.4, beam_h - 0.02), col)
            z_cur += beam_h
            layer += 1
        add_prism_x(bm, (-7.0, H_FRONT), (7.0, H_BACK), (-7.0, H_BACK), 8.0 - beam_thickness/2.0, 8.0 + beam_thickness/2.0, t_wall_b)
        
    # 4. Door frame
    def _fn_door(bm):
        door_x = -2.7
        door_half_w = 1.6
        door_h = 5.4
        add_box(bm, (door_x - door_half_w, -7.0, (FLOOR_Z + door_h)/2.0), (0.42, 0.95, door_h - FLOOR_Z), t_trims)
        add_box(bm, (door_x + door_half_w, -7.0, (FLOOR_Z + door_h)/2.0), (0.42, 0.95, door_h - FLOOR_Z), t_trims)
        add_box(bm, (door_x, -7.0, door_h + 0.15), (door_half_w * 2.0 + 0.6, 1.05, 0.45), t_trims)
        add_box(bm, (door_x, -7.4, FLOOR_Z - 0.12), (3.8, 0.9, 0.25), t_sill)
        add_box(bm, (door_x, -8.1, FLOOR_Z - 0.28), (4.2, 0.7, 0.22), t_trims)
        
    # 5. Windows
    def _fn_windows(bm):
        w1_x, w1_y, w1_z = 4.0, -7.0, 3.9
        w1_w, w1_h = 3.2, 2.8
        add_box(bm, (w1_x, w1_y, w1_z + w1_h/2.0 + 0.1), (w1_w + 0.4, 0.95, 0.25), t_trims)
        add_box(bm, (w1_x, w1_y - 0.1, w1_z - w1_h/2.0 - 0.12), (w1_w + 0.6, 1.25, 0.28), t_sill)
        add_box(bm, (w1_x - w1_w/2.0 - 0.1, w1_y, w1_z), (0.25, 0.95, w1_h), t_trims)
        add_box(bm, (w1_x + w1_w/2.0 + 0.1, w1_y, w1_z), (0.25, 0.95, w1_h), t_trims)
        add_box(bm, (w1_x, w1_y, w1_z), (0.16, 0.8, w1_h), t_crossbars)
        add_box(bm, (w1_x, w1_y, w1_z), (w1_w, 0.8, 0.16), t_crossbars)
        add_box(bm, (w1_x, w1_y, w1_z), (w1_w - 0.05, 0.1, w1_h - 0.05), t_glass)

        w2_x, w2_y, w2_z = -8.0, 0.0, 3.9
        w2_w, w2_h = 3.2, 2.8
        add_box(bm, (w2_x, w2_y, w2_z + w2_h/2.0 + 0.1), (0.95, w2_w + 0.4, 0.25), t_trims)
        add_box(bm, (w2_x - 0.1, w2_y, w2_z - w2_h/2.0 - 0.12), (1.25, w2_w + 0.6, 0.28), t_sill)
        add_box(bm, (w2_x, w2_y - w2_w/2.0 - 0.1, w2_z), (0.95, 0.25, w2_h), t_trims)
        add_box(bm, (w2_x, w2_y + w2_w/2.0 + 0.1, w2_z), (0.95, 0.25, w2_h), t_trims)
        add_box(bm, (w2_x, w2_y, w2_z), (0.8, 0.16, w2_h), t_crossbars)
        add_box(bm, (w2_x, w2_y, w2_z), (0.8, w2_w, 0.16), t_crossbars)
        add_box(bm, (w2_x, w2_y, w2_z), (0.1, w2_w - 0.05, w2_h - 0.05), t_glass)

    # 6. Roof (offset Z by -0.082)
    def _fn_roof(bm):
        roof_w = W_X + 2.8
        z_offset = -0.082
        z_ef = Z_EAVE_FRONT + z_offset
        z_eb = Z_EAVE_BACK + z_offset
        rafter_xs = [-8.8, -4.4, 0.0, 4.4, 8.8]
        for rx in rafter_xs:
            add_sloped_slab(bm, rx - 0.24, rx + 0.24, Y_EAVE_FRONT, Y_EAVE_BACK, z_ef, z_eb, thickness=0.45, offset_n=-0.45, color_name=t_rafters)
        add_sloped_slab(bm, -roof_w/2.0, roof_w/2.0, Y_EAVE_FRONT, Y_EAVE_BACK, z_ef, z_eb, thickness=0.35, offset_n=0.0, color_name=t_roof_deck)
        num_battens = 9
        for i in range(num_battens):
            bx = -roof_w/2.0 + (i + 0.5) * (roof_w / num_battens)
            add_sloped_slab(bm, bx - 0.12, bx + 0.12, Y_EAVE_FRONT - 0.1, Y_EAVE_BACK + 0.1, z_ef, z_eb, thickness=0.15, offset_n=0.35, color_name=t_roof_battens)
        add_sloped_slab(bm, -roof_w/2.0 - 0.15, -roof_w/2.0 + 0.15, Y_EAVE_FRONT - 0.2, Y_EAVE_BACK + 0.2, z_ef, z_eb, thickness=0.65, offset_n=-0.35, color_name=t_rafters)
        add_sloped_slab(bm, roof_w/2.0 - 0.15, roof_w/2.0 + 0.15, Y_EAVE_FRONT - 0.2, Y_EAVE_BACK + 0.2, z_ef, z_eb, thickness=0.65, offset_n=-0.35, color_name=t_rafters)
        add_box(bm, (0.0, Y_EAVE_FRONT, z_ef + 0.15), (roof_w + 0.4, 0.45, 0.5), t_rafters)
        add_box(bm, (0.0, Y_EAVE_BACK, z_eb + 0.15), (roof_w + 0.4, 0.45, 0.5), t_rafters)

    # 7. Chimney (incorporates scale (1.0, 1.0, 0.707) and offset (-0.423, 0.0, 4.453))
    def _fn_chimney(bm):
        chim_x = -4.8 - 0.423
        chim_y = 4.0
        t = (chim_y - Y_EAVE_FRONT) / (Y_EAVE_BACK - Y_EAVE_FRONT)
        roof_z = Z_EAVE_FRONT - t * (Z_EAVE_FRONT - Z_EAVE_BACK)
        
        h_scale = 0.707
        base_cz = roof_z + 0.8
        add_box(bm, (chim_x, chim_y, base_cz), (1.5, 1.5, 3.2 * h_scale), t_chim_base)
        add_box(bm, (chim_x, chim_y, roof_z + 0.35 * h_scale), (1.8, 1.8, 0.35 * h_scale), t_chim_flashing)
        add_box(bm, (chim_x, chim_y, roof_z + 1.5 * h_scale), (1.65, 1.65, 0.25 * h_scale), t_chim_flashing)
        add_cylinder(bm, (chim_x, chim_y, roof_z + 2.8 * h_scale), radius=0.42, height=2.4 * h_scale, segments=12, color_name=t_chim_pipe)
        add_cylinder(bm, (chim_x, chim_y, roof_z + 3.6 * h_scale), radius=0.48, height=0.18 * h_scale, segments=12, color_name=t_chim_band)
        add_cylinder(bm, (chim_x, chim_y, roof_z + 4.15 * h_scale), radius=0.75, height=0.16 * h_scale, segments=12, color_name=t_chim_pipe)
        for ang in [0, math.pi/2, math.pi, 3*math.pi/2]:
            px = chim_x + 0.35 * math.cos(ang)
            py = chim_y + 0.35 * math.sin(ang)
            add_box(bm, (px, py, roof_z + 3.95 * h_scale), (0.08, 0.08, 0.35 * h_scale), t_chim_band)

    parts_builders = [
        ("Foundation", _fn_found),
        ("PlankFloor", _fn_floor),
        ("TimberWalls", _fn_walls),
        ("DoorFrame", _fn_door),
        ("Windows", _fn_windows),
        ("SinglePitchRoof", _fn_roof),
        ("Chimney", _fn_chimney),
    ]
    
    parts = []
    for p_name, p_fn in parts_builders:
        mesh = bpy.data.meshes.new(f"{theme['name']}_{p_name}Mesh")
        bm = bmesh.new()
        p_fn(bm)
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = False
        mesh.update()
        obj = bpy.data.objects.new(f"{theme['name']}_{p_name}", mesh)
        obj.parent = root
        obj.data.materials.append(mat)
        bpy.context.collection.objects.link(obj)
        parts.append(obj)
        
    return root, parts

THEMES = [
    {
        "id": "player_house",
        "name": "PlayerHouse",
        "title": "Дом игрока (Уютный медовый сруб)",
        "found_stone1": "stone_dark",
        "found_stone2": "stone_slate",
        "found_rim": "wood_bark",
        "found_joist": "wood_cedar",
        "floor_planks": ["wood_pine", "wood_honey_oak", "wood_pine", "wood_honey_oak", "wood_birch"],
        "wall_a": "wood_honey_oak",
        "wall_b": "wood_cedar",
        "trims": "wood_cedar",
        "sill": "wood_walnut",
        "crossbars": "wood_pine",
        "glass": "ice_light",
        "rafters": "wood_cedar",
        "roof_deck": "wood_walnut",
        "roof_battens": "wood_cedar",
        "chim_base": "stone_dark",
        "chim_flashing": "stone_slate",
        "chim_pipe": "cast_iron",
        "chim_band": "gunmetal",
    },
    {
        "id": "food_shop",
        "name": "FoodShop",
        "title": "Продуктовая лавка (Тёплый терракотовый сруб & Соломенная крыша)",
        "found_stone1": "clay_brick",
        "found_stone2": "stone_dark",
        "found_rim": "wood_bark",
        "found_joist": "wood_cedar",
        "floor_planks": ["wood_cedar", "clay_brick", "wood_walnut", "wood_cedar", "wood_pine"],
        "wall_a": "clay_brick",
        "wall_b": "wood_cedar",
        "trims": "crimson_dark",
        "sill": "wood_walnut",
        "crossbars": "wood_pine",
        "glass": "ice_light",
        "rafters": "crimson_dark",
        "roof_deck": "twine_straw",
        "roof_battens": "spark_yellow",
        "chim_base": "clay_brick",
        "chim_flashing": "stone_slate",
        "chim_pipe": "copper_bronze",
        "chim_band": "cast_iron",
    },
    {
        "id": "clothing_shop",
        "name": "ClothingShop",
        "title": "Магазин одежды (Светлая берёза & Полуночно-синяя крыша)",
        "found_stone1": "stone_slate",
        "found_stone2": "slate_light",
        "found_rim": "wood_bark",
        "found_joist": "steel_light",
        "floor_planks": ["wood_birch", "wood_pine", "wood_birch", "slate_light", "wood_pine"],
        "wall_a": "wood_birch",
        "wall_b": "slate_light",
        "trims": "wood_bark",
        "sill": "slate_light",
        "crossbars": "wood_birch",
        "glass": "aqua_bright",
        "rafters": "midnight_blue",
        "roof_deck": "midnight_blue",
        "roof_battens": "denim_blue",
        "chim_base": "slate_light",
        "chim_flashing": "stone_slate",
        "chim_pipe": "gunmetal",
        "chim_band": "steel_light",
    },
    {
        "id": "hunter_cabin",
        "name": "HunterCabin",
        "title": "Охотничья заимка (Выветренное серое дерево & Обожжённая крыша)",
        "found_stone1": "stone_dark",
        "found_stone2": "iron_band",
        "found_rim": "wood_burnt",
        "found_joist": "wood_burnt",
        "floor_planks": ["wood_weathered", "wood_bark", "wood_weathered", "wood_burnt", "wood_weathered"],
        "wall_a": "wood_weathered",
        "wall_b": "wood_bark",
        "trims": "wood_bark",
        "sill": "wood_burnt",
        "crossbars": "wood_weathered",
        "glass": "ice_deep",
        "rafters": "wood_burnt",
        "roof_deck": "wood_burnt",
        "roof_battens": "wood_bark",
        "chim_base": "stone_dark",
        "chim_flashing": "iron_band",
        "chim_pipe": "pitch_black",
        "chim_band": "iron_band",
    }
]

def run():
    print("🚀 Starting generation and rendering for 4 building variations...")
    for theme in THEMES:
        clear_scene()
        setup_scene()
        root, parts = build_house_model(theme)
        
        # Setup Lighting & Camera
        scene = bpy.context.scene
        scene.render.resolution_x = 1280
        scene.render.resolution_y = 800
        scene.render.film_transparent = False
        
        world = bpy.data.worlds.new("ShowcaseWorld")
        scene.world = world
        world.use_nodes = True
        bg_node = world.node_tree.nodes.get("Background")
        if bg_node:
            bg_node.inputs['Color'].default_value = (0.86, 0.90, 0.95, 1.0)
            bg_node.inputs['Strength'].default_value = 0.90
            
        sun_data = bpy.data.lights.new(name="SunKey", type='SUN')
        sun_data.energy = 4.2
        sun_data.color = (1.0, 0.96, 0.90)
        sun_obj = bpy.data.objects.new(name="SunKey", object_data=sun_data)
        sun_obj.rotation_euler = (math.radians(45), math.radians(22), math.radians(-40))
        bpy.context.collection.objects.link(sun_obj)
        
        fill_data = bpy.data.lights.new(name="SkyFill", type='SUN')
        fill_data.energy = 1.8
        fill_data.color = (0.72, 0.86, 1.0)
        fill_obj = bpy.data.objects.new(name="SkyFill", object_data=fill_data)
        fill_obj.rotation_euler = (math.radians(65), math.radians(-35), math.radians(140))
        bpy.context.collection.objects.link(fill_obj)
        
        cam_data = bpy.data.cameras.new("Cam")
        cam_data.lens = 45
        cam_obj = bpy.data.objects.new("Cam", cam_data)
        bpy.context.collection.objects.link(cam_obj)
        scene.camera = cam_obj
        
        target_pos = Vector((0.0, 0.0, 4.8))
        
        # 1. Primary Iso View
        cam_pos_iso = Vector((24.0, -25.0, 16.0))
        cam_obj.location = cam_pos_iso
        direction = target_pos - cam_pos_iso
        cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
        
        img_iso_path = os.path.join(ARTIFACTS_DIR, f"building_{theme['id']}_iso.png")
        scene.render.filepath = img_iso_path
        bpy.ops.render.render(write_still=True)
        print(f"📸 Rendered ISO: {img_iso_path}")
        
        # 2. Front Facade View
        cam_pos_front = Vector((0.0, -28.0, 6.2))
        cam_obj.location = cam_pos_front
        direction_front = target_pos - cam_pos_front
        cam_obj.rotation_euler = direction_front.to_track_quat('-Z', 'Y').to_euler()
        
        img_front_path = os.path.join(ARTIFACTS_DIR, f"building_{theme['id']}_front.png")
        scene.render.filepath = img_front_path
        bpy.ops.render.render(write_still=True)
        print(f"📸 Rendered FRONT: {img_front_path}")
        
        # Save individual blend and exports
        b_path = os.path.join(SOURCES_DIR, f"{theme['id']}.blend")
        bpy.ops.wm.save_as_mainfile(filepath=b_path)
        
        fbx_path = os.path.join(MODELS_DIR, f"{theme['id']}.fbx")
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=False,
            axis_forward='-Z',
            axis_up='Y',
            apply_scale_options='FBX_SCALE_ALL'
        )
        print(f"💾 Exported: {b_path} and {fbx_path}")

    print("✨ All 4 building variations successfully generated and rendered!")

if __name__ == "__main__":
    run()
