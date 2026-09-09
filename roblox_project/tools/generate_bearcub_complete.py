"""
    tools/generate_bearcub_complete.py
    Comprehensive 3D Polar Bear Cub (Chibi Bear Pet) Generator and Exporter for Roblox Studio:
    1. Multi-Part Modular Hierarchy (Gold Standard SKILL.md: Root empty at 0,0,0 + child meshes)
    2. Adorable Chibi Bear Cub aesthetics (chubby body, round teddy-bear ears with pink inner pads, gentle blue eyes with sparkles, button black nose, cozy glacier-blue winter collar with gold bell, 4 stubby chubby paws with dark pads, round button tail)
    3. Blender native (+Z Up, -Y Front) coordinate standard
    4. Exports clean .fbx, .obj, .blend to assets/models/ and assets/models/pets/
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
import mathutils
from mathutils import Matrix, Euler, Vector
import math
import os
import shutil

MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
PETS_DIR = os.path.join(MODELS_DIR, "pets")
SOURCES_DIR = os.path.join(MODELS_DIR, "sources")
TEXTURES_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures"
PALETTE_PATH = os.path.join(TEXTURES_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"
BRAIN_DIR = r"C:\Users\pc1\.gemini\antigravity-ide\brain\d766dd16-21c3-45ee-9fb6-b500cd9314ac"

for d in [MODELS_DIR, PETS_DIR, SOURCES_DIR, BRAIN_DIR]:
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

def create_mesh_part(name, build_fn, parent_obj, mat):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    build_fn(bm)
    bm.to_mesh(mesh)
    bm.free()
    
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    obj.parent = parent_obj
    bpy.context.collection.objects.link(obj)
    
    for poly in mesh.polygons:
        poly.use_smooth = False
    return obj

def build_and_export_bearcub():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    root = bpy.data.objects.new("BearCub", None)
    root.empty_display_type = 'PLAIN_AXES'
    root.empty_display_size = 1.0
    bpy.context.collection.objects.link(root)
    
    parts = []

    # 1. TORSO & CHUBBY UNDERBELLY (+Z Up, -Y Front) - Chunky cuddly polar bear cub body
    def build_torso(bm):
        t1 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0, 0.78)) @ Matrix.Diagonal((1.05, 1.15, 0.88, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
        
        # Slightly softer shaded belly
        t2 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0, 0.54)) @ Matrix.Diagonal((0.82, 0.95, 0.44, 1.0)))
        for v in t2['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_ambient")
    
    obj_torso = create_mesh_part("Torso", build_torso, root, mat)
    parts.append(obj_torso)

    # 2. GLACIER BLUE WINTER COLLAR WITH GOLD BELL
    def build_collar(bm):
        res = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -0.48, 1.10)) @ Euler((math.radians(-32), 0, 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.92, 0.92, 0.18, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "ice_glacier")
        
        bell = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.16, matrix=Matrix.Translation((0, -0.72, 0.96)))
        for v in bell['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "gold_pure")
    
    obj_collar = create_mesh_part("Collar", build_collar, root, mat)
    parts.append(obj_collar)

    # 3. CHUBBY ROUND TEDDY BEAR HEAD & PUFFY CHEEKS
    def build_head(bm):
        h = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -0.70, 1.42)) @ Matrix.Diagonal((1.08, 0.98, 0.96, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
        
        # Puffy Cheek L
        chL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.52, -0.72, 1.30)) @ Matrix.Diagonal((0.26, 0.44, 0.44, 1.0)))
        for v in chL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")
            
        # Puffy Cheek R
        chR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.52, -0.72, 1.30)) @ Matrix.Diagonal((0.26, 0.44, 0.44, 1.0)))
        for v in chR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")
    
    obj_head = create_mesh_part("Head", build_head, root, mat)
    parts.append(obj_head)

    # 4. ROUND MUZZLE & SHINY BUTTON NOSE
    def build_muzzle(bm):
        m = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -1.18, 1.25)) @ Matrix.Diagonal((0.56, 0.44, 0.44, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
        
        # Button black nose
        nose = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -1.40, 1.38)) @ Matrix.Diagonal((0.24, 0.16, 0.18, 1.0)))
        for v in nose['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
    
    obj_muzzle = create_mesh_part("Muzzle", build_muzzle, root, mat)
    parts.append(obj_muzzle)

    # 5. ROUND TEDDY BEAR EARS WITH PINK INNER PADS
    def build_ears(bm):
        # Round Ear L
        earL = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.28, matrix=Matrix.Translation((-0.46, -0.60, 1.88)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
        
        # Pink Inner Pad L
        padL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.46, -0.74, 1.88)) @ Matrix.Diagonal((0.20, 0.06, 0.22, 1.0)))
        for v in padL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pink_soft")

        # Round Ear R
        earR = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.28, matrix=Matrix.Translation((0.46, -0.60, 1.88)))
        for v in earR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")
            
        # Pink Inner Pad R
        padR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.46, -0.74, 1.88)) @ Matrix.Diagonal((0.20, 0.06, 0.22, 1.0)))
        for v in padR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pink_soft")
            
    obj_ears = create_mesh_part("Ears", build_ears, root, mat)
    parts.append(obj_ears)

    # 6. GENTLE SAPPHIRE BLUE EYES WITH SPARKLE GLINTS
    def build_eyes(bm):
        # Left Eye (Deep blue iris + black pupil + sparkle)
        eyeL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.28, -1.14, 1.48)) @ Matrix.Diagonal((0.20, 0.08, 0.22, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "ice_deep")
        
        pupilL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.27, -1.18, 1.48)) @ Matrix.Diagonal((0.12, 0.04, 0.14, 1.0)))
        for v in pupilL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
            
        glintL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.23, -1.20, 1.54)) @ Matrix.Diagonal((0.06, 0.03, 0.06, 1.0)))
        for v in glintL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")

        # Right Eye
        eyeR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.28, -1.14, 1.48)) @ Matrix.Diagonal((0.20, 0.08, 0.22, 1.0)))
        for v in eyeR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "ice_deep")
            
        pupilR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.27, -1.18, 1.48)) @ Matrix.Diagonal((0.12, 0.04, 0.14, 1.0)))
        for v in pupilR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
            
        glintR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.23, -1.20, 1.54)) @ Matrix.Diagonal((0.06, 0.03, 0.06, 1.0)))
        for v in glintR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")

    obj_eyes = create_mesh_part("Eyes", build_eyes, root, mat)
    parts.append(obj_eyes)

    # 7. 4 THICK STUBBY PAWS WITH DARK PADS
    def make_bear_leg(name, x, y):
        def build_leg(bm):
            upper = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((x, y, 0.44)) @ Matrix.Diagonal((0.38, 0.42, 0.44, 1.0)))
            for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
            
            paw = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((x, y - 0.04, 0.15)) @ Matrix.Diagonal((0.42, 0.46, 0.24, 1.0)))
            for v in paw['verts']:
                for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")
                
            pad = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((x, y - 0.06, 0.04)) @ Matrix.Diagonal((0.26, 0.30, 0.04, 1.0)))
            for v in pad['verts']:
                for f in v.link_faces: set_bmesh_uv(bm, [f], "stone_dark")
                
        return create_mesh_part(name, build_leg, root, mat)

    parts.append(make_bear_leg("Leg_FL", -0.38, -0.32))
    parts.append(make_bear_leg("Leg_FR",  0.38, -0.32))
    parts.append(make_bear_leg("Leg_BL", -0.38,  0.32))
    parts.append(make_bear_leg("Leg_BR",  0.38,  0.32))

    # 8. CUTE LITTLE ROUND BUTTON TAIL
    def build_tail(bm):
        tail = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.22, matrix=Matrix.Translation((0, 0.62, 0.76)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "snow_pure")
            
    obj_tail = create_mesh_part("Tail", build_tail, root, mat)
    parts.append(obj_tail)

    # EXPORT FILES
    out_fbx_main = os.path.join(MODELS_DIR, "bearcub.fbx")
    out_fbx_pet = os.path.join(PETS_DIR, "bearcub.fbx")
    out_obj_main = os.path.join(MODELS_DIR, "bearcub.obj")
    out_obj_pet = os.path.join(PETS_DIR, "bearcub.obj")
    out_blend_main = os.path.join(MODELS_DIR, "bearcub.blend")
    out_blend_pet = os.path.join(PETS_DIR, "bearcub.blend")
    out_source_blend = os.path.join(SOURCES_DIR, "bearcub_source.blend")

    # Select all parts + root for export
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = root

    bpy.ops.wm.save_as_mainfile(filepath=out_source_blend)
    shutil.copyfile(out_source_blend, out_blend_main)
    shutil.copyfile(out_source_blend, out_blend_pet)

    bpy.ops.export_scene.fbx(
        filepath=out_fbx_main,
        use_selection=True,
        axis_forward='-Z',
        axis_up='Y',
        apply_scale_options='FBX_SCALE_ALL',
        bake_space_transform=False,
        mesh_smooth_type='OFF',
        add_leaf_bones=False
    )
    shutil.copyfile(out_fbx_main, out_fbx_pet)

    bpy.ops.wm.obj_export(
        filepath=out_obj_main,
        export_selected_objects=True,
        forward_axis='NEGATIVE_Z',
        up_axis='Y',
        apply_modifiers=True
    )
    shutil.copyfile(out_obj_main, out_obj_pet)

    total_tris = sum(len(p.data.polygons) * 2 for p in parts)
    print(f"SUCCESS: BearCub generated! Parts={len(parts)}, Triangles={total_tris}")
    return len(parts), total_tris

part_count, tri_count = build_and_export_bearcub()
print(f"RESULT_BEARCUB_PARTS_{part_count}_TRIS_{tri_count}")
"""

def send_blender_code(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(25.0)
    s.connect((HOST, PORT))
    cmd = {"type": "execute_code", "params": {"code": code}}
    s.sendall(json.dumps(cmd).encode('utf-8'))
    
    chunks = []
    while True:
        try:
            chunk = s.recv(8192)
            if not chunk: break
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
        return json.loads(b"".join(chunks).decode('utf-8'))
    return {"status": "error", "message": "No response"}

def main():
    print("Generating 3D Polar Bear Cub in Blender 5.0...")
    res = send_blender_code(BLENDER_SCRIPT)
    print("Blender Response:", json.dumps(res, indent=2))

if __name__ == "__main__":
    main()
