"""
    tools/generate_wolfpup_complete.py
    Comprehensive 3D Friendly Wolf Pup Generator and Exporter for Roblox Studio:
    1. Multi-Part Modular Hierarchy (Gold Standard SKILL.md: Root empty at 0,0,0 + child meshes)
    2. Adorable, friendly puppy aesthetics (chibi proportions, fluffy cheeks, puppy eyes with glints, happy tongue, cozy collar with gold bell, fluffy curved tail)
    3. Blender native (+Z Up, -Y Front) coordinate standard for seamless modeling and FBX export
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

for d in [MODELS_DIR, PETS_DIR, SOURCES_DIR]:
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

def build_and_export_wolfpup():
    clear_scene()
    setup_scene()
    mat = get_or_create_palette_mat()
    
    root = bpy.data.objects.new("WolfPup", None)
    root.empty_display_type = 'PLAIN_AXES'
    root.empty_display_size = 1.0
    bpy.context.collection.objects.link(root)
    
    parts = []

    # 1. TORSO & CHUBBY UNDERBELLY (+Z Up, -Y Front)
    def build_torso(bm):
        # Main fluffy body
        t1 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0, 0.75)) @ Matrix.Diagonal((0.85, 0.95, 0.75, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Soft warm cream underbelly
        t2 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0, 0.52)) @ Matrix.Diagonal((0.65, 0.85, 0.38, 1.0)))
        for v in t2['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_birch")
    
    obj_torso = create_mesh_part("Torso", build_torso, root, mat)
    parts.append(obj_torso)

    # 2. FLUFFY CHEST MANE
    def build_chest(bm):
        c1 = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=6, radius1=0.42, radius2=0.10, depth=0.50, matrix=Matrix.Translation((0, -0.45, 0.82)) @ Euler((math.radians(-50), 0, 0)).to_matrix().to_4x4())
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_birch")
    
    obj_chest = create_mesh_part("ChestFluff", build_chest, root, mat)
    parts.append(obj_chest)

    # 3. CUTE COLLAR & GOLD BELL
    def build_collar(bm):
        # Cozy warm collar
        res = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -0.46, 1.06)) @ Euler((math.radians(-35), 0, 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.78, 0.78, 0.16, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "meat_steak")
        
        # Shiny golden bell / charm
        bell = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.14, matrix=Matrix.Translation((0, -0.66, 0.92)))
        for v in bell['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "gold_pure")
    
    obj_collar = create_mesh_part("Collar", build_collar, root, mat)
    parts.append(obj_collar)

    # 4. CHIBI PUPPY HEAD & FLUFFY CHEEKS
    def build_head(bm):
        # Rounded chibi head
        h = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -0.65, 1.35)) @ Matrix.Diagonal((0.95, 0.85, 0.85, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Fluffy cheek L
        chL = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=5, radius1=0.28, radius2=0.06, depth=0.36, matrix=Matrix.Translation((-0.52, -0.65, 1.22)) @ Euler((math.radians(35), math.radians(-35), 0)).to_matrix().to_4x4())
        for v in chL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_birch")
            
        # Fluffy cheek R
        chR = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=5, radius1=0.28, radius2=0.06, depth=0.36, matrix=Matrix.Translation((0.52, -0.65, 1.22)) @ Euler((math.radians(35), math.radians(35), 0)).to_matrix().to_4x4())
        for v in chR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_birch")
    
    obj_head = create_mesh_part("Head", build_head, root, mat)
    parts.append(obj_head)

    # 5. CUTE SNOUT, NOSE & HAPPY TONGUE
    def build_muzzle(bm):
        # Short cute snout
        m = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -1.05, 1.20)) @ Matrix.Diagonal((0.46, 0.40, 0.36, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_birch")
        
        # Button black nose
        nose = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -1.25, 1.30)) @ Matrix.Diagonal((0.20, 0.14, 0.14, 1.0)))
        for v in nose['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
            
        # Pink tongue
        tongue = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, -1.15, 1.08)) @ Euler((math.radians(-15), 0, 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.18, 0.22, 0.08, 1.0)))
        for v in tongue['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pink_soft")
    
    obj_muzzle = create_mesh_part("Muzzle", build_muzzle, root, mat)
    parts.append(obj_muzzle)

    # 6. SOFT PUPPY EARS WITH PINK LINING
    def build_ears(bm):
        # Left ear
        earL = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=5, radius1=0.26, radius2=0.05, depth=0.52, matrix=Matrix.Translation((-0.38, -0.55, 1.78)) @ Euler((math.radians(15), math.radians(-18), 0)).to_matrix().to_4x4())
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Pink inner flap L
        flapL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.36, -0.62, 1.74)) @ Euler((math.radians(15), math.radians(-18), 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.16, 0.05, 0.30, 1.0)))
        for v in flapL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pink_soft")

        # Right ear
        earR = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=5, radius1=0.26, radius2=0.05, depth=0.52, matrix=Matrix.Translation((0.38, -0.55, 1.78)) @ Euler((math.radians(15), math.radians(18), 0)).to_matrix().to_4x4())
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Pink inner flap R
        flapR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.36, -0.62, 1.74)) @ Euler((math.radians(15), math.radians(18), 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.16, 0.05, 0.30, 1.0)))
        for v in flapR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pink_soft")
            
    obj_ears = create_mesh_part("Ears", build_ears, root, mat)
    parts.append(obj_ears)

    # 7. BIG EXPRESSIVE PUPPY EYES WITH SPARKLE GLINTS
    def build_eyes(bm):
        # Left Eye (Sky-blue iris + dark pupil + white glint)
        eyeL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.26, -1.02, 1.40)) @ Matrix.Diagonal((0.20, 0.08, 0.22, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "aqua_bright")
        
        pupilL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.25, -1.06, 1.40)) @ Matrix.Diagonal((0.12, 0.04, 0.14, 1.0)))
        for v in pupilL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
            
        glintL = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((-0.21, -1.08, 1.46)) @ Matrix.Diagonal((0.06, 0.03, 0.06, 1.0)))
        for v in glintL['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")

        # Right Eye
        eyeR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.26, -1.02, 1.40)) @ Matrix.Diagonal((0.20, 0.08, 0.22, 1.0)))
        for v in eyeR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "aqua_bright")
            
        pupilR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.25, -1.06, 1.40)) @ Matrix.Diagonal((0.12, 0.04, 0.14, 1.0)))
        for v in pupilR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "pitch_black")
            
        glintR = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0.21, -1.08, 1.46)) @ Matrix.Diagonal((0.06, 0.03, 0.06, 1.0)))
        for v in glintR['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "snow_pure")

    obj_eyes = create_mesh_part("Eyes", build_eyes, root, mat)
    parts.append(obj_eyes)

    # 8. 4 CUTE STUBBY LEGS & WHITE PAWS
    def build_leg(bm, side_x, side_y, is_front):
        # Upper Leg
        thigh = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((side_x * 0.36, side_y * 0.32, 0.38)) @ Matrix.Diagonal((0.30, 0.30, 0.40, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Lower Paw (fluffy cream)
        paw = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((side_x * 0.36, side_y * 0.32 - (0.05 if is_front else -0.02), 0.12)) @ Matrix.Diagonal((0.34, 0.38, 0.24, 1.0)))
        for v in paw['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_birch")

    obj_fl = create_mesh_part("Leg_FL", lambda bm: build_leg(bm, -1, -1, True), root, mat)
    obj_fr = create_mesh_part("Leg_FR", lambda bm: build_leg(bm, 1, -1, True), root, mat)
    obj_bl = create_mesh_part("Leg_BL", lambda bm: build_leg(bm, -1, 1, False), root, mat)
    obj_br = create_mesh_part("Leg_BR", lambda bm: build_leg(bm, 1, 1, False), root, mat)
    parts.extend([obj_fl, obj_fr, obj_bl, obj_br])

    # 9. FLUFFY WAGGING TAIL WITH CREAM TIP
    def build_tail(bm):
        # Base tail
        t1 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0.46, 0.85)) @ Euler((math.radians(-40), 0, 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.28, 0.38, 0.28, 1.0)))
        for f in bm.faces: set_bmesh_uv(bm, [f], "wood_cedar")
        
        # Mid curl
        t2 = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, 0.68, 1.10)) @ Euler((math.radians(-65), 0, 0)).to_matrix().to_4x4() @ Matrix.Diagonal((0.30, 0.36, 0.30, 1.0)))
        for v in t2['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_cedar")
            
        # Fluffy cream tip
        t3 = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=6, radius1=0.20, radius2=0.04, depth=0.38, matrix=Matrix.Translation((0, 0.82, 1.32)) @ Euler((math.radians(-80), 0, 0)).to_matrix().to_4x4())
        for v in t3['verts']:
            for f in v.link_faces: set_bmesh_uv(bm, [f], "wood_birch")

    obj_tail = create_mesh_part("Tail", build_tail, root, mat)
    parts.append(obj_tail)

    # Save Blend source
    blend_source = os.path.join(SOURCES_DIR, "wolfpup_source.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_source)
    print("Saved source blend:", blend_source)

    # Export Multi-Part FBX (Gold Standard: Root empty + all children)
    for p in parts:
        p.select_set(True)
    root.select_set(True)
    bpy.context.view_layer.objects.active = root

    for dest_dir in [MODELS_DIR, PETS_DIR]:
        fbx_path = os.path.join(dest_dir, "wolfpup.fbx")
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            apply_unit_scale=True,
            bake_space_transform=False,
            object_types={'EMPTY', 'MESH'}
        )
        print("Exported FBX:", fbx_path)

    # Export OBJ & Blend copies
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.duplicate()
    bpy.ops.object.join()
    combined_obj = bpy.context.view_layer.objects.active
    combined_obj.name = "WolfPupMesh"

    for dest_dir in [MODELS_DIR, PETS_DIR]:
        obj_path = os.path.join(dest_dir, "wolfpup.obj")
        bpy.ops.wm.obj_export(
            filepath=obj_path,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y'
        )
        print("Exported OBJ:", obj_path)
        
        blend_path = os.path.join(dest_dir, "wolfpup.blend")
        shutil.copyfile(blend_source, blend_path)

    bpy.data.objects.remove(combined_obj, do_unlink=True)

    total_tris = sum(len(p.data.polygons) * 2 for p in parts)
    print(f"Total WolfPup Parts: {len(parts)} | Total Tris: ~{total_tris}")
    return len(parts), total_tris

part_count, tri_count = build_and_export_wolfpup()
print(f"RESULT_WOLFPUP_PARTS_{part_count}_TRIS_{tri_count}")
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
    print("Generating 3D Friendly Wolf Pup in Blender 5.0...")
    res = send_blender_code(BLENDER_SCRIPT)
    print("Blender Response:", json.dumps(res, indent=2))

if __name__ == "__main__":
    main()
