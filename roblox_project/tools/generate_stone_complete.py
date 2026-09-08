"""
    tools/generate_stone_complete.py
    Faceted / Blocky / Cubic Low-Poly Stylized Stone Boulder Generator for Blender 5.0 and Roblox Studio:
    - Stylized chiseled cubic geometry (Zero spheres, crisp polygonal bevels, stepped stone slabs)
    - Multi-Part Modular & Single-Mesh formats
    - 100% Palette UV mapping (stone_slate, stone_dark, iron_band, slate_light, steel_light)
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

MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
RESOURCES_DIR = os.path.join(MODELS_DIR, "resources")
NATURE_DIR = os.path.join(MODELS_DIR, "nature")
SOURCES_DIR = os.path.join(MODELS_DIR, "sources")
TEXTURES_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures"
PALETTE_PATH = os.path.join(TEXTURES_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

for d in [MODELS_DIR, RESOURCES_DIR, NATURE_DIR, SOURCES_DIR]:
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
    bsdf.inputs['Roughness'].default_value = 0.85
    
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

def create_faceted_block_mesh(name, vert_coords, face_indices, face_colors, mat):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    bm_verts = [bm.verts.new(pt) for pt in vert_coords]
    bm.verts.ensure_lookup_table()
    
    for indices, col_name in zip(face_indices, face_colors):
        f_verts = [bm_verts[i] for i in indices]
        face = bm.faces.new(f_verts)
        set_bmesh_uv(bm, [face], col_name)
        
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

def build_and_export_blocky_stone():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    root = bpy.data.objects.new("Stone", None)
    root.empty_display_type = 'PLAIN_AXES'
    root.empty_display_size = 1.0
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    
    parts = []
    
    # -------------------------------------------------------------------------
    # 1. ОСНОВНОЙ КУБИЧЕСКИЙ ГРАНЕНЫЙ ВАЛУН (Main Faceted Cube Boulder)
    # Рубленый 10-гранный куб со срезанными углами и плоскими гранями
    # -------------------------------------------------------------------------
    # 10 вершин основного граненого куба
    main_verts = [
        # Нижние вершины (Z = 0.0)
        (-0.95, -0.80, 0.0),  # 0: BL_bot (Front-Left)
        ( 0.75, -0.85, 0.0),  # 1: BR_bot (Front-Right)
        ( 0.90,  0.65, 0.0),  # 2: TR_bot (Back-Right)
        (-0.80,  0.80, 0.0),  # 3: TL_bot (Back-Left)
        # Средний пояс фасок (Z = 0.75..0.95)
        (-1.10, -0.55, 0.75), # 4: Mid_L
        ( 0.95, -0.60, 0.75), # 5: Mid_FR
        ( 1.05,  0.45, 0.85), # 6: Mid_BR
        (-0.70,  0.90, 0.80), # 7: Mid_BL
        (-0.25, -0.98, 0.85), # 8: Mid_Front
        # Верхняя грань (Z = 1.45..1.60)
        (-0.55, -0.45, 1.55), # 9: Top_FL
        ( 0.50, -0.40, 1.60), # 10: Top_FR
        ( 0.45,  0.45, 1.50), # 11: Top_BR
        (-0.45,  0.50, 1.45), # 12: Top_BL
    ]
    
    main_faces = [
        # Основание (дно)
        [0, 1, 2, 3],
        # Нижний пояс граней
        [0, 8, 4],
        [0, 1, 8],
        [1, 5, 8],
        [1, 2, 6, 5],
        [2, 3, 7, 6],
        [3, 0, 4, 7],
        # Верхний пояс граней
        [4, 8, 9],
        [8, 5, 10, 9],
        [5, 6, 11, 10],
        [6, 7, 12, 11],
        [7, 4, 9, 12],
        # Верхняя плоская грань
        [9, 10, 11, 12]
    ]
    
    main_colors = [
        "iron_band",   # Дно
        "stone_dark",  # FL_low
        "stone_dark",  # Front_low
        "stone_slate", # FR_low
        "stone_dark",  # Right_low
        "iron_band",   # Back_low
        "stone_dark",  # Left_low
        "stone_slate", # FL_up
        "slate_light", # Front_up
        "steel_light", # FR_up
        "stone_slate", # Back_up
        "stone_dark",  # Left_up
        "slate_light"  # Top plate
    ]
    
    parts.append(create_faceted_block_mesh("MainBoulder", main_verts, main_faces, main_colors, mat))

    # -------------------------------------------------------------------------
    # 2. БОКОВОЙ ПРЯМОУГОЛЬНЫЙ СТУПЕНЧАТЫЙ БЛОК (Side Stepped Rock Slab)
    # -------------------------------------------------------------------------
    side_verts = [
        ( 0.65, -0.45, 0.0),   # 0
        ( 1.45, -0.40, 0.0),   # 1
        ( 1.40,  0.50, 0.0),   # 2
        ( 0.60,  0.45, 0.0),   # 3
        ( 0.70, -0.40, 0.65),  # 4
        ( 1.35, -0.35, 0.72),  # 5
        ( 1.30,  0.45, 0.68),  # 6
        ( 0.65,  0.40, 0.60),  # 7
    ]
    side_faces = [
        [0, 1, 2, 3],
        [0, 4, 5, 1],
        [1, 5, 6, 2],
        [2, 6, 7, 3],
        [3, 7, 4, 0],
        [4, 7, 6, 5],
    ]
    side_colors = [
        "iron_band",
        "stone_slate",
        "stone_dark",
        "iron_band",
        "stone_dark",
        "steel_light",
    ]
    parts.append(create_faceted_block_mesh("SideSlab", side_verts, side_faces, side_colors, mat))

    # -------------------------------------------------------------------------
    # 3. МАЛЫЙ УГЛОВОЙ КУБИЧЕСКИЙ ОСКОЛОК (Corner Pebble Wedge)
    # -------------------------------------------------------------------------
    pebble_verts = [
        (-1.15, -0.20, 0.0),  # 0
        (-0.75, -0.25, 0.0),  # 1
        (-0.70,  0.30, 0.0),  # 2
        (-1.10,  0.25, 0.0),  # 3
        (-1.05, -0.15, 0.40), # 4
        (-0.78, -0.18, 0.45), # 5
        (-0.75,  0.22, 0.42), # 6
        (-1.02,  0.20, 0.38), # 7
    ]
    pebble_faces = [
        [0, 1, 2, 3],
        [0, 4, 5, 1],
        [1, 5, 6, 2],
        [2, 6, 7, 3],
        [3, 7, 4, 0],
        [4, 7, 6, 5],
    ]
    pebble_colors = [
        "iron_band",
        "stone_slate",
        "stone_dark",
        "iron_band",
        "stone_dark",
        "slate_light",
    ]
    parts.append(create_faceted_block_mesh("CornerPebble", pebble_verts, pebble_faces, pebble_colors, mat))

    # -------------------------------------------------------------------------
    # 4. ВЕРХНИЙ СРЕЗАННЫЙ ГРАНЕНЫЙ СКОЛ (Top Crest Facet)
    # -------------------------------------------------------------------------
    crest_verts = [
        (-0.35, -0.25, 1.55), # 0
        ( 0.30, -0.20, 1.60), # 1
        ( 0.25,  0.30, 1.50), # 2
        (-0.30,  0.32, 1.45), # 3
        (-0.05,  0.05, 1.88), # 4: Apex peak
    ]
    crest_faces = [
        [0, 1, 2, 3],
        [0, 4, 1],
        [1, 4, 2],
        [2, 4, 3],
        [3, 4, 0],
    ]
    crest_colors = [
        "slate_light",
        "slate_light",
        "steel_light",
        "stone_slate",
        "stone_slate",
    ]
    parts.append(create_faceted_block_mesh("TopCrest", crest_verts, crest_faces, crest_colors, mat))

    # Привязка всех частей к root
    for p in parts:
        p.parent = root
        
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCES_DIR, "stone_source.blend"))
    
    # Экспорт Multi-Part FBX
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = root
    
    for dest_dir in [MODELS_DIR, RESOURCES_DIR, NATURE_DIR]:
        fbx_path = os.path.join(dest_dir, "stone.fbx")
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
        
    # Экспорт монолитного OBJ и .blend
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
    single_mesh.name = "StoneMesh"
    single_mesh.data.materials.clear()
    single_mesh.data.materials.append(mat)
    if single_mesh.data.uv_layers.active:
        single_mesh.data.uv_layers.active.name = "UVMap"
        
    for dest_dir in [MODELS_DIR, RESOURCES_DIR, NATURE_DIR]:
        obj_path = os.path.join(dest_dir, "stone.obj")
        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True
        )
        blend_path = os.path.join(dest_dir, "stone.blend")
        bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.data.objects.remove(single_mesh, do_unlink=True)
    
    total_tris = sum(sum(len(p.vertices) - 2 for p in part.data.polygons) for part in parts)
    print(f"Total Blocky Stone Model Parts: {len(parts)} | Total Triangles: {total_tris}")
    return len(parts), total_tris

part_count, tri_count = build_and_export_blocky_stone()
print(f"RESULT_STONE_PARTS_{part_count}_TRIS_{tri_count}")
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
                print("Blender Stone Execution Response:")
                print(json.dumps(res, indent=2))
                return
            except json.JSONDecodeError:
                continue
        except:
            break
    s.close()

if __name__ == "__main__":
    main()
