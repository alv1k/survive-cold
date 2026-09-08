"""
    tools/generate_food_complete.py
    Full 3D Food Asset Generator for Blender 5.0 and Roblox Studio:
    1. 🍫 Bar: Chocolate energy bar in gold foil wrapper
    2. 🍞 Bread: Rustic golden crust loaf with diagonal crown scores
    3. 🥔 Chips: Puffed snack bag with crimped seals and red flavor band
    4. 🥫 Soup: Steel tin can with red soup label and pull-ring tab
    5. 🌶️ Pepper: Curved red chili pepper horn with green stem
    6. ☕ Coffee: Insulated thermo paper cup with brown heat sleeve and sip lid
    7. 🥩 Steak: Seared juicy meat steak with ivory bone
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
FOOD_DIR = os.path.join(MODELS_DIR, "food")
SOURCES_DIR = os.path.join(MODELS_DIR, "sources")
TEXTURES_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures"
PALETTE_PATH = os.path.join(TEXTURES_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

for d in [MODELS_DIR, FOOD_DIR, SOURCES_DIR]:
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

def make_box_mesh(bm, x0, x1, y0, y1, z0, z1, col_name):
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
    set_bmesh_uv(bm, f, col_name)
    return f

def make_prism_mesh(bm, p1, p2, p3, p4, p5, p6, col_name):
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
    set_bmesh_uv(bm, f, col_name)
    return f

def make_cylinder_mesh(bm, r_bot, r_top, z_bot, z_top, n_segs, col_side, col_top, col_bot, rot_offset=0):
    v_bot, v_top = [], []
    for i in range(n_segs):
        ang = 2 * math.pi * i / n_segs + rot_offset
        v_bot.append(bm.verts.new((r_bot * math.cos(ang), r_bot * math.sin(ang), z_bot)))
        v_top.append(bm.verts.new((r_top * math.cos(ang), r_top * math.sin(ang), z_top)))
    
    f_side = []
    for i in range(n_segs):
        i_next = (i + 1) % n_segs
        f_side.append(bm.faces.new((v_bot[i], v_bot[i_next], v_top[i_next], v_top[i])))
    set_bmesh_uv(bm, f_side, col_side)
    
    if col_bot:
        f_b = bm.faces.new(list(reversed(v_bot)))
        set_bmesh_uv(bm, [f_b], col_bot)
    if col_top:
        f_t = bm.faces.new(v_top)
        set_bmesh_uv(bm, [f_t], col_top)

def export_model_package(name, obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
        
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    for dest in [MODELS_DIR, FOOD_DIR]:
        fbx_p = os.path.join(dest, f"{name}.fbx")
        bpy.ops.export_scene.fbx(
            filepath=fbx_p,
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            apply_scale_options='FBX_SCALE_NONE',
            bake_space_transform=False,
            add_leaf_bones=False
        )
        obj_p = os.path.join(dest, f"{name}.obj")
        bpy.ops.wm.obj_export(
            filepath=obj_p,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True
        )
        blend_p = os.path.join(dest, f"{name}.blend")
        bpy.ops.wm.save_as_mainfile(filepath=blend_p)
    print(f"Exported {name} to models and food dirs!")

# =============================================================================
# 1. 🍫 BAR (Energy Bar in Gold Foil)
# =============================================================================
def build_bar():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    # Фольгированная обертка
    make_box_mesh(bm, -0.32, 0.32, -0.65, 0.15, 0.0, 0.28, "fiber_gold")
    # Зубчатые запаянные концы
    make_box_mesh(bm, -0.35, 0.35, -0.75, -0.65, 0.08, 0.20, "relic_gold")
    make_box_mesh(bm, -0.35, 0.35, 0.15, 0.22, 0.08, 0.20, "relic_gold")
    # Открытый аппетитный кусочек шоколада с кубиками
    make_box_mesh(bm, -0.26, 0.26, 0.22, 0.65, 0.04, 0.24, "wood_walnut")
    make_box_mesh(bm, -0.22, -0.04, 0.26, 0.42, 0.24, 0.28, "soil_dark")
    make_box_mesh(bm, 0.04, 0.22, 0.26, 0.42, 0.24, 0.28, "soil_dark")
    make_box_mesh(bm, -0.22, -0.04, 0.46, 0.62, 0.24, 0.28, "soil_dark")
    make_box_mesh(bm, 0.04, 0.22, 0.46, 0.62, 0.24, 0.28, "soil_dark")
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("BarMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Bar", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("bar", obj, mat)

# =============================================================================
# 2. 🍞 BREAD (Rustic Artisan Loaf)
# =============================================================================
def build_bread():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    # Нижнее основание буханки
    make_box_mesh(bm, -0.45, 0.45, -0.70, 0.70, 0.0, 0.35, "wood_cedar")
    # Верхняя пышная золотистая корка
    make_prism_mesh(bm, (-0.48, -0.72, 0.35), (0.48, -0.72, 0.35), (0.0, -0.72, 0.68),
                        (-0.48, 0.72, 0.35), (0.48, 0.72, 0.35), (0.0, 0.72, 0.68), "wood_honey_oak")
    # 3 диагональных надреза на корочке
    for y_mid in [-0.35, 0.0, 0.35]:
        make_box_mesh(bm, -0.32, 0.32, y_mid - 0.05, y_mid + 0.05, 0.52, 0.70, "fire_core")
        
    bm.normal_update()
    mesh = bpy.data.meshes.new("BreadMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Bread", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("bread", obj, mat)

# =============================================================================
# 3. 🥔 CHIPS (Crispy Snack Bag)
# =============================================================================
def build_chips():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    # Пузатый пакет
    make_box_mesh(bm, -0.42, 0.42, -0.22, 0.22, 0.15, 0.75, "spark_yellow")
    # Верхний и нижний запаянные швы
    make_box_mesh(bm, -0.44, 0.44, -0.04, 0.04, 0.75, 0.88, "flame_orange")
    make_box_mesh(bm, -0.44, 0.44, -0.04, 0.04, 0.0, 0.15, "flame_orange")
    # Красная центральная вкусовая эмблема
    make_box_mesh(bm, -0.32, 0.32, -0.25, -0.20, 0.35, 0.58, "soup_can_red")
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("ChipsMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Chips", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("chips", obj, mat)

# =============================================================================
# 4. 🥫 SOUP (Tin Can with Red Label & Ring Pull)
# =============================================================================
def build_soup():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    n = 10
    # Нижний стальной обод
    make_cylinder_mesh(bm, 0.38, 0.38, 0.0, 0.10, n, "steel_light", None, "slate_light")
    # Центральная красная этикетка супа
    make_cylinder_mesh(bm, 0.39, 0.39, 0.10, 0.70, n, "soup_can_red", None, None)
    # Верхний стальной обод и крышка
    make_cylinder_mesh(bm, 0.38, 0.38, 0.70, 0.80, n, "steel_light", "slate_light", None)
    # Стальное кольцо-открывашка на крышке
    make_box_mesh(bm, -0.12, 0.12, -0.16, 0.16, 0.80, 0.84, "steel_light")
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("SoupMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Soup", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("soup", obj, mat)

# =============================================================================
# 5. 🌶️ PEPPER (Hot Chili Horn)
# =============================================================================
def build_pepper():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    # Стручок перца (конусные секции с изгибом)
    make_prism_mesh(bm, (-0.18, -0.18, 0.70), (0.18, -0.18, 0.70), (0.0, -0.22, 0.35),
                        (-0.18, 0.18, 0.70), (0.18, 0.18, 0.70), (0.0, 0.22, 0.35), "pepper_chili")
    make_prism_mesh(bm, (-0.14, -0.14, 0.35), (0.14, -0.14, 0.35), (0.0, -0.05, 0.0),
                        (-0.14, 0.14, 0.35), (0.14, 0.14, 0.35), (0.0, 0.15, 0.0), "soup_can_red")
    # Зеленый черенок и чашелистик
    make_box_mesh(bm, -0.16, 0.16, -0.16, 0.16, 0.70, 0.78, "leaf_green")
    make_box_mesh(bm, -0.05, 0.05, -0.05, 0.05, 0.78, 0.98, "pine_green")
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("PepperMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Pepper", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("pepper", obj, mat)

# =============================================================================
# 6. ☕ COFFEE (Thermo Paper Cup with Sleeve and Sip Lid)
# =============================================================================
def build_coffee():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    n = 10
    # Белый бумажный стакан (конус расширяется вверх)
    make_cylinder_mesh(bm, 0.28, 0.38, 0.0, 0.75, n, "snow_ambient", None, "slate_light")
    # Картонный крафтовый термоманжет
    make_cylinder_mesh(bm, 0.32, 0.36, 0.25, 0.55, n, "wood_honey_oak", None, None)
    # Темная крышка с носиком
    make_cylinder_mesh(bm, 0.40, 0.40, 0.75, 0.85, n, "gunmetal", "cast_iron", None)
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("CoffeeMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Coffee", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("coffee", obj, mat)

# =============================================================================
# 7. 🥩 STEAK (Juicy Ribeye / T-Bone Steak)
# =============================================================================
def build_steak():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    bm = bmesh.new()
    # Сочный кусок мяса
    make_box_mesh(bm, -0.55, 0.55, -0.45, 0.45, 0.0, 0.28, "meat_steak")
    # Полосы прожарки гриля
    make_box_mesh(bm, -0.45, -0.25, -0.42, 0.42, 0.28, 0.31, "wood_burnt")
    make_box_mesh(bm, -0.10, 0.10, -0.42, 0.42, 0.28, 0.31, "wood_burnt")
    make_box_mesh(bm, 0.25, 0.45, -0.42, 0.42, 0.28, 0.31, "wood_burnt")
    # Белая косточка сбоку
    make_cylinder_mesh(bm, 0.12, 0.12, 0.0, 0.30, 8, "snow_pure", "snow_pure", "snow_pure")
    
    bm.normal_update()
    mesh = bpy.data.meshes.new("SteakMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Steak", mesh)
    bpy.context.collection.objects.link(obj)
    export_model_package("steak", obj, mat)

# =============================================================================
# MAIN BUILD ALL
# =============================================================================
build_bar()
build_bread()
build_chips()
build_soup()
build_pepper()
build_coffee()
build_steak()
print("RESULT_ALL_7_FOOD_ASSETS_EXPORTED_SUCCESSFULLY")
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
                print("Blender Food Execution Response:")
                print(json.dumps(res, indent=2))
                return
            except json.JSONDecodeError:
                continue
        except:
            break
    s.close()

if __name__ == "__main__":
    main()
