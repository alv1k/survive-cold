"""
    tools/generate_player_house_complete.py
    Comprehensive 3D Player House Generator for Roblox Studio:
    - 🏡 Дощатый пол (Plank Wooden Floor with individual longitudinal timber planks)
    - 🪟 2 Окна с наличниками и перекрестьями (1 Front Window + 1 Side Window)
    - 🚪 1 Дверной проем (Wide entrance doorway with timber posts & lintel)
    - 🌲 Стены из бруса с перерубами (Stacked Timber Beams with notched corner joints)
    - 📐 Односкатная крыша с вылетом (Single-Pitch Shed Roof with rafters, eaves & fascia trims)
    - 💨 Труба для печки с оголовком (Stone chimney base + cast iron stove pipe with cap)
    - Multi-angle rendering (Isometric, Front, Side, Interior) for user review
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
    """Adds an axis-aligned box into bmesh and assigns UV color."""
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
        (0, 1, 2, 3), # Bottom (-Z)
        (4, 7, 6, 5), # Top (+Z)
        (0, 4, 5, 1), # Front (-Y)
        (1, 5, 6, 2), # Right (+X)
        (2, 6, 7, 3), # Back (+Y)
        (3, 7, 4, 0), # Left (-X)
    ]
    
    created_faces = []
    for f_idx in face_indices:
        f = bm.faces.new([verts[i] for i in f_idx])
        created_faces.append(f)
    
    set_bmesh_uv(bm, created_faces, color_name)
    return created_faces

def add_sloped_slab(bm, x_min, x_max, y_start, y_end, z_start, z_end, thickness, offset_n, color_name):
    """Adds a perfectly planar sloped slab (for single-pitch roof, rafters, planks)."""
    dy = y_end - y_start
    dz = z_end - z_start
    hyp = math.sqrt(dy * dy + dz * dz)
    
    # Unit tangent and normal vectors along Y-Z plane
    ty = dy / hyp
    tz = dz / hyp
    ny = -tz  # Normal points upward perpendicular to the slope
    nz = ty
    
    # Bottom vertices (offset by offset_n)
    p0 = (x_min, y_start + ny * offset_n, z_start + nz * offset_n)
    p1 = (x_max, y_start + ny * offset_n, z_start + nz * offset_n)
    p2 = (x_max, y_end + ny * offset_n, z_end + nz * offset_n)
    p3 = (x_min, y_end + ny * offset_n, z_end + nz * offset_n)
    
    # Top vertices (offset by offset_n + thickness)
    top_off = offset_n + thickness
    p4 = (x_min, y_start + ny * top_off, z_start + nz * top_off)
    p5 = (x_max, y_start + ny * top_off, z_start + nz * top_off)
    p6 = (x_max, y_end + ny * top_off, z_end + nz * top_off)
    p7 = (x_min, y_end + ny * top_off, z_end + nz * top_off)
    
    verts = [bm.verts.new(p) for p in [p0, p1, p2, p3, p4, p5, p6, p7]]
    
    face_indices = [
        (0, 1, 2, 3), # Bottom
        (4, 7, 6, 5), # Top
        (0, 4, 5, 1), # Front
        (1, 5, 6, 2), # Right
        (2, 6, 7, 3), # Back
        (3, 7, 4, 0), # Left
    ]
    
    faces = [bm.faces.new([verts[i] for i in idx]) for idx in face_indices]
    set_bmesh_uv(bm, faces, color_name)
    return faces

def add_prism_x(bm, pt_a, pt_b, pt_c, x_min, x_max, color_name):
    """Adds a triangular prism along X axis for roof gable fill."""
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
    """Adds a vertical cylinder into bmesh."""
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

def create_mesh_object(name, builder_fn, parent, mat):
    mesh = bpy.data.meshes.new(name + "Mesh")
    bm = bmesh.new()
    builder_fn(bm)
    bm.to_mesh(mesh)
    bm.free()
    
    for poly in mesh.polygons:
        poly.use_smooth = False
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.parent = parent
    if mat:
        obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    return obj

# =============================================================================
# HOUSE PARAMETERS & BUILDERS
# =============================================================================

W_X = 16.0    # House Width (-8.0 to +8.0)
D_Y = 14.0    # House Depth (-7.0 to +7.0)
H_FRONT = 8.6 # Front Wall Top Z
H_BACK = 6.4  # Back Wall Top Z
FLOOR_Z = 0.5 # Floor Level

# Roof slope plane:
Y_EAVE_FRONT = -8.8
Z_EAVE_FRONT = 9.1
Y_EAVE_BACK = 8.8
Z_EAVE_BACK = 6.3

def build_foundation(bm):
    # Corner foundation stone footings
    corners = [(-8.2, -7.2), (8.2, -7.2), (-8.2, 7.2), (8.2, 7.2), (0.0, -7.2), (0.0, 7.2)]
    for cx, cy in corners:
        add_box(bm, (cx, cy, 0.25), (1.6, 1.6, 0.5), "stone_dark")
        add_box(bm, (cx, cy, 0.05), (1.8, 1.8, 0.15), "stone_slate")
        
    # Foundation heavy squared rim beams
    add_box(bm, (0.0, -7.0, 0.35), (16.6, 0.85, 0.5), "wood_bark") # Front rim
    add_box(bm, (0.0, 7.0, 0.35), (16.6, 0.85, 0.5), "wood_bark")  # Back rim
    add_box(bm, (-8.0, 0.0, 0.35), (0.85, 14.0, 0.5), "wood_bark") # Left rim
    add_box(bm, (8.0, 0.0, 0.35), (0.85, 14.0, 0.5), "wood_bark")  # Right rim
    # Center joist beam
    add_box(bm, (0.0, 0.0, 0.3), (0.6, 14.0, 0.4), "wood_cedar")

def build_plank_floor(bm):
    # Дощатый пол: 14 individual longitudinal planks along Y with rich wooden variations
    num_planks = 14
    plank_width = (W_X - 1.4) / num_planks # ~1.04 studs per plank
    plank_colors = ["wood_pine", "wood_honey_oak", "wood_pine", "wood_honey_oak", "wood_birch"]
    
    for i in range(num_planks):
        px = - (W_X - 1.4)/2.0 + (i + 0.5) * plank_width
        col = plank_colors[i % len(plank_colors)]
        jitter_z = (i % 3) * 0.015
        add_box(bm, (px, 0.0, FLOOR_Z - 0.05 + jitter_z), (plank_width - 0.04, D_Y - 1.4, 0.12), col)

def build_timber_walls(bm):
    beam_h = 0.55
    beam_thickness = 0.68
    
    # 1. Back Wall (Z from FLOOR_Z to H_BACK) - Solid stacked timber beams
    z_cur = FLOOR_Z + beam_h / 2.0
    layer = 0
    while z_cur < H_BACK:
        col = "wood_honey_oak" if layer % 2 == 0 else "wood_cedar"
        # Notched overhanging corner joints (перерубы)
        add_box(bm, (0.0, 7.0, z_cur), (W_X + 1.4, beam_thickness, beam_h - 0.02), col)
        z_cur += beam_h
        layer += 1
        
    # 2. Front Wall:
    # Doorway at X in [-4.4, -1.0], Window 1 at X in [2.4, 5.6]
    z_cur = FLOOR_Z + beam_h / 2.0
    layer = 0
    while z_cur < H_FRONT:
        col = "wood_honey_oak" if layer % 2 == 0 else "wood_cedar"
        if z_cur < 2.4:
            # Below window: left pillar + full span under window to the right
            add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
            add_box(bm, (3.5, -7.0, z_cur), (9.2, beam_thickness, beam_h - 0.02), col)
        elif z_cur < 5.4:
            # Window & Door level: left pillar, center pier, right pier
            add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
            add_box(bm, (0.7, -7.0, z_cur), (3.4, beam_thickness, beam_h - 0.02), col)
            add_box(bm, (6.8, -7.0, z_cur), (2.4, beam_thickness, beam_h - 0.02), col)
        elif z_cur < 5.8:
            # Above window, below door lintel top
            add_box(bm, (-6.3, -7.0, z_cur), (3.6, beam_thickness, beam_h - 0.02), col)
            add_box(bm, (3.5, -7.0, z_cur), (9.2, beam_thickness, beam_h - 0.02), col)
        else:
            # Full span beam above doorway and window (lintel level to roof)
            add_box(bm, (0.0, -7.0, z_cur), (W_X + 1.4, beam_thickness, beam_h - 0.02), col)
        z_cur += beam_h
        layer += 1
        
    # 3. Left Wall (with Window 2 at Y in [-1.5, 1.5], Z in [2.4, 5.4])
    z_cur = FLOOR_Z + beam_h / 2.0
    layer = 0
    while z_cur < H_BACK:
        col = "wood_honey_oak" if layer % 2 == 0 else "wood_cedar"
        if z_cur >= 2.4 and z_cur <= 5.4:
            # Front of window
            add_box(bm, (-8.0, -4.3, z_cur), (beam_thickness, 5.4, beam_h - 0.02), col)
            # Rear of window
            add_box(bm, (-8.0, 4.3, z_cur), (beam_thickness, 5.4, beam_h - 0.02), col)
        else:
            add_box(bm, (-8.0, 0.0, z_cur), (beam_thickness, D_Y + 1.4, beam_h - 0.02), col)
        z_cur += beam_h
        layer += 1
        
    # Left Wall Gable (Slanted top triangular fill from H_FRONT at Y=-7 to H_BACK at Y=7)
    add_prism_x(bm, (-7.0, H_FRONT), (7.0, H_BACK), (-7.0, H_BACK), -8.0 - beam_thickness/2.0, -8.0 + beam_thickness/2.0, "wood_cedar")

    # 4. Right Wall (Solid timber beams + Gable)
    z_cur = FLOOR_Z + beam_h / 2.0
    layer = 0
    while z_cur < H_BACK:
        col = "wood_honey_oak" if layer % 2 == 0 else "wood_cedar"
        add_box(bm, (8.0, 0.0, z_cur), (beam_thickness, D_Y + 1.4, beam_h - 0.02), col)
        z_cur += beam_h
        layer += 1
        
    # Right Wall Gable
    add_prism_x(bm, (-7.0, H_FRONT), (7.0, H_BACK), (-7.0, H_BACK), 8.0 - beam_thickness/2.0, 8.0 + beam_thickness/2.0, "wood_cedar")

def build_door_frame(bm):
    # 1 Дверной проем (Doorway at X = -2.7)
    door_x = -2.7
    door_half_w = 1.6
    door_h = 5.4
    
    # Left & right door timber posts
    add_box(bm, (door_x - door_half_w, -7.0, (FLOOR_Z + door_h)/2.0), (0.42, 0.95, door_h - FLOOR_Z), "wood_cedar")
    add_box(bm, (door_x + door_half_w, -7.0, (FLOOR_Z + door_h)/2.0), (0.42, 0.95, door_h - FLOOR_Z), "wood_cedar")
    # Lintel beam
    add_box(bm, (door_x, -7.0, door_h + 0.15), (door_half_w * 2.0 + 0.6, 1.05, 0.45), "wood_cedar")
    # Door threshold step (крыльцо/ступень)
    add_box(bm, (door_x, -7.4, FLOOR_Z - 0.12), (3.8, 0.9, 0.25), "wood_walnut")
    add_box(bm, (door_x, -8.1, FLOOR_Z - 0.28), (4.2, 0.7, 0.22), "wood_cedar")

def build_windows(bm):
    # 2 Окна:
    # Window 1: Front Facade at X = 4.0, Y = -7.0, Z = 3.9 (Width = 3.0, Height = 2.8)
    # Window 2: Left Side Wall at X = -8.0, Y = 0.0, Z = 3.9 (Width = 3.0, Height = 2.8)
    
    # --- WINDOW 1: FRONT FACADE ---
    w1_x, w1_y, w1_z = 4.0, -7.0, 3.9
    w1_w, w1_h = 3.2, 2.8
    # Top & Bottom frames
    add_box(bm, (w1_x, w1_y, w1_z + w1_h/2.0 + 0.1), (w1_w + 0.4, 0.95, 0.25), "wood_cedar")
    add_box(bm, (w1_x, w1_y - 0.1, w1_z - w1_h/2.0 - 0.12), (w1_w + 0.6, 1.25, 0.28), "wood_walnut") # Window sill
    # Left & Right frames
    add_box(bm, (w1_x - w1_w/2.0 - 0.1, w1_y, w1_z), (0.25, 0.95, w1_h), "wood_cedar")
    add_box(bm, (w1_x + w1_w/2.0 + 0.1, w1_y, w1_z), (0.25, 0.95, w1_h), "wood_cedar")
    # Crossbars
    add_box(bm, (w1_x, w1_y, w1_z), (0.16, 0.8, w1_h), "wood_pine")
    add_box(bm, (w1_x, w1_y, w1_z), (w1_w, 0.8, 0.16), "wood_pine")
    # Glass pane
    add_box(bm, (w1_x, w1_y, w1_z), (w1_w - 0.05, 0.1, w1_h - 0.05), "ice_light")

    # --- WINDOW 2: LEFT SIDE WALL ---
    w2_x, w2_y, w2_z = -8.0, 0.0, 3.9
    w2_w, w2_h = 3.2, 2.8
    # Top & Bottom frames
    add_box(bm, (w2_x, w2_y, w2_z + w2_h/2.0 + 0.1), (0.95, w2_w + 0.4, 0.25), "wood_cedar")
    add_box(bm, (w2_x - 0.1, w2_y, w2_z - w2_h/2.0 - 0.12), (1.25, w2_w + 0.6, 0.28), "wood_walnut") # Window sill
    # Front & Rear frames
    add_box(bm, (w2_x, w2_y - w2_w/2.0 - 0.1, w2_z), (0.95, 0.25, w2_h), "wood_cedar")
    add_box(bm, (w2_x, w2_y + w2_w/2.0 + 0.1, w2_z), (0.95, 0.25, w2_h), "wood_cedar")
    # Crossbars
    add_box(bm, (w2_x, w2_y, w2_z), (0.8, 0.16, w2_h), "wood_pine")
    add_box(bm, (w2_x, w2_y, w2_z), (0.8, w2_w, 0.16), "wood_pine")
    # Glass pane
    add_box(bm, (w2_x, w2_y, w2_z), (0.1, w2_w - 0.05, w2_h - 0.05), "ice_light")

def build_single_pitch_roof(bm):
    # Односкатная крыша (Single-Pitch Roof):
    # Slopes down continuously from Front eave (Y = -8.8, Z = 9.1) to Back eave (Y = 8.8, Z = 6.3)
    roof_w = W_X + 2.8 # 18.8 studs wide (overhang on both sides)
    
    # 1. Structural Under-Roof Rafter Beams (5 rafters spanning front to back)
    rafter_xs = [-8.8, -4.4, 0.0, 4.4, 8.8]
    for rx in rafter_xs:
        add_sloped_slab(bm, rx - 0.24, rx + 0.24, Y_EAVE_FRONT, Y_EAVE_BACK, Z_EAVE_FRONT, Z_EAVE_BACK, thickness=0.45, offset_n=-0.45, color_name="wood_cedar")
        
    # 2. Main Solid Roof Deck (Сплошной дощатый настил крыши)
    add_sloped_slab(bm, -roof_w/2.0, roof_w/2.0, Y_EAVE_FRONT, Y_EAVE_BACK, Z_EAVE_FRONT, Z_EAVE_BACK, thickness=0.35, offset_n=0.0, color_name="wood_walnut")
    
    # 3. Longitudinal Roof Plank Battens (Продольные рейки и нащельники)
    num_battens = 9
    for i in range(num_battens):
        bx = -roof_w/2.0 + (i + 0.5) * (roof_w / num_battens)
        add_sloped_slab(bm, bx - 0.12, bx + 0.12, Y_EAVE_FRONT - 0.1, Y_EAVE_BACK + 0.1, Z_EAVE_FRONT, Z_EAVE_BACK, thickness=0.15, offset_n=0.35, color_name="wood_cedar")
        
    # 4. Fascia Wind Trims (Ветровые доски по бокам)
    add_sloped_slab(bm, -roof_w/2.0 - 0.15, -roof_w/2.0 + 0.15, Y_EAVE_FRONT - 0.2, Y_EAVE_BACK + 0.2, Z_EAVE_FRONT, Z_EAVE_BACK, thickness=0.65, offset_n=-0.35, color_name="wood_cedar")
    add_sloped_slab(bm, roof_w/2.0 - 0.15, roof_w/2.0 + 0.15, Y_EAVE_FRONT - 0.2, Y_EAVE_BACK + 0.2, Z_EAVE_FRONT, Z_EAVE_BACK, thickness=0.65, offset_n=-0.35, color_name="wood_cedar")
    
    # 5. Front & Back Eave Fascia Edge Planks
    add_box(bm, (0.0, Y_EAVE_FRONT, Z_EAVE_FRONT + 0.15), (roof_w + 0.4, 0.45, 0.5), "wood_cedar")
    add_box(bm, (0.0, Y_EAVE_BACK, Z_EAVE_BACK + 0.15), (roof_w + 0.4, 0.45, 0.5), "wood_cedar")

def build_chimney(bm):
    # Труба для печки (Stove pipe positioned at rear-left X = -4.8, Y = 4.0)
    chim_x = -4.8
    chim_y = 4.0
    
    # Exact roof surface Z at this chimney location:
    t = (chim_y - Y_EAVE_FRONT) / (Y_EAVE_BACK - Y_EAVE_FRONT)
    roof_z = Z_EAVE_FRONT - t * (Z_EAVE_FRONT - Z_EAVE_BACK) # ~ 7.0
    
    # 1. Square stone masonry base rising from inside up through the roof
    add_box(bm, (chim_x, chim_y, (roof_z + 1.2)/2.0 + 2.0), (1.5, 1.5, 4.2), "stone_dark")
    # Stone collar flashing at roof line
    add_box(bm, (chim_x, chim_y, roof_z + 0.35), (1.8, 1.8, 0.35), "stone_slate")
    # Stone chimney crown
    add_box(bm, (chim_x, chim_y, roof_z + 1.5), (1.65, 1.65, 0.25), "stone_slate")
    
    # 2. Cast iron round stove pipe emerging from stone crown
    add_cylinder(bm, (chim_x, chim_y, roof_z + 2.8), radius=0.42, height=2.4, segments=12, color_name="cast_iron")
    # Metal banded ring
    add_cylinder(bm, (chim_x, chim_y, roof_z + 3.6), radius=0.48, height=0.18, segments=12, color_name="gunmetal")
    # Chimney rain cap / spark arrestor
    add_cylinder(bm, (chim_x, chim_y, roof_z + 4.15), radius=0.75, height=0.16, segments=12, color_name="cast_iron")
    # Cap support brackets (4 metal pins)
    for ang in [0, math.pi/2, math.pi, 3*math.pi/2]:
        px = chim_x + 0.35 * math.cos(ang)
        py = chim_y + 0.35 * math.sin(ang)
        add_box(bm, (px, py, roof_z + 3.95), (0.08, 0.08, 0.35), "gunmetal")

# =============================================================================
# MAIN ASSEMBLY & RENDER PIPELINE
# =============================================================================

def generate_player_house():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    # Create Root Empty
    root = bpy.data.objects.new("PlayerHouse", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    
    # Build Modular Components
    p_found = create_mesh_object("House_Foundation", build_foundation, root, mat)
    p_floor = create_mesh_object("House_PlankFloor", build_plank_floor, root, mat)
    p_walls = create_mesh_object("House_TimberWalls", build_timber_walls, root, mat)
    p_door = create_mesh_object("House_DoorFrame", build_door_frame, root, mat)
    p_windows = create_mesh_object("House_Windows", build_windows, root, mat)
    p_roof = create_mesh_object("House_SinglePitchRoof", build_single_pitch_roof, root, mat)
    p_chimney = create_mesh_object("House_Chimney", build_chimney, root, mat)
    
    parts = [p_found, p_floor, p_walls, p_door, p_windows, p_roof, p_chimney]
    total_tris = sum(len(p.data.polygons) * 2 for p in parts)
    print(f"🏡 [PlayerHouse] 3D Model created successfully with {len(parts)} modular components, ~{total_tris} triangles!")
    
    # Export Models (.blend, .obj, .fbx)
    blend_path = os.path.join(SOURCES_DIR, "player_house.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"💾 Saved Blender source: {blend_path}")
    
    obj_path = os.path.join(MODELS_DIR, "player_house.obj")
    bpy.ops.wm.obj_export(filepath=obj_path)
    print(f"💾 Exported OBJ: {obj_path}")
    
    fbx_path = os.path.join(MODELS_DIR, "player_house.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=False,
        axis_forward='-Z',
        axis_up='Y',
        apply_scale_options='FBX_SCALE_ALL'
    )
    print(f"💾 Exported FBX: {fbx_path}")
    
    # Render multi-angle showcase screenshots
    render_showcase_views(root)

def render_showcase_views(target_obj):
    scene = bpy.context.scene
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 800
    scene.render.film_transparent = False
    
    # World lighting
    world = bpy.data.worlds.new("HouseWorld")
    scene.world = world
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = (0.84, 0.89, 0.95, 1.0)
        bg_node.inputs['Strength'].default_value = 0.90
        
    # Sun Light (Warm Key Light)
    sun_data = bpy.data.lights.new(name="SunKey", type='SUN')
    sun_data.energy = 4.2
    sun_data.color = (1.0, 0.96, 0.90)
    sun_obj = bpy.data.objects.new(name="SunKey", object_data=sun_data)
    sun_obj.rotation_euler = (math.radians(45), math.radians(22), math.radians(-40))
    bpy.context.collection.objects.link(sun_obj)
    
    # Fill Light (Cool Sky Light)
    fill_data = bpy.data.lights.new(name="SkyFill", type='SUN')
    fill_data.energy = 1.8
    fill_data.color = (0.72, 0.86, 1.0)
    fill_obj = bpy.data.objects.new(name="SkyFill", object_data=fill_data)
    fill_obj.rotation_euler = (math.radians(65), math.radians(-35), math.radians(140))
    bpy.context.collection.objects.link(fill_obj)
    
    # Camera
    cam_data = bpy.data.cameras.new("ShowcaseCam")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new("ShowcaseCam", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    
    views = [
        ("house_iso_front.png", Vector((24.0, -25.0, 16.0)), Vector((0.0, 0.0, 4.8)), 45),
        ("house_front_facade.png", Vector((0.0, -28.0, 6.2)), Vector((0.0, 0.0, 4.8)), 45),
        ("house_side_window.png", Vector((-26.0, 0.0, 8.2)), Vector((0.0, 0.0, 4.8)), 45),
        ("house_iso_back.png", Vector((-22.0, 22.0, 15.0)), Vector((0.0, 0.0, 4.8)), 45),
        ("house_interior.png", Vector((-2.7, -9.5, 3.8)), Vector((0.0, 2.0, 3.5)), 28),
    ]
    
    for filename, cam_pos, target_pos, lens in views:
        cam_data.lens = lens
        cam_obj.location = cam_pos
        direction = target_pos - cam_pos
        rot_quat = direction.to_track_quat('-Z', 'Y')
        cam_obj.rotation_euler = rot_quat.to_euler()
        
        out_path = os.path.join(ARTIFACTS_DIR, filename)
        scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"📸 Rendered showcase view: {out_path}")

if __name__ == "__main__":
    generate_player_house()
