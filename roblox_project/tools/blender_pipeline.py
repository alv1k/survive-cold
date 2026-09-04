"""
    tools/blender_pipeline.py
    Blender 5.0+ Automation & Export Pipeline for Roblox Studio.
    
    Functions:
    1. setup_roblox_scene(): Sets units, grid, and camera clipping to Roblox studs.
    2. export_model(filepath, format='FBX'/'OBJ'): Validates polycount, applies transforms, and exports with -Z Forward / +Y Up.
    3. generate_starter_assets(): Procedurally generates base low-poly 3D models for all catalog items.
"""

import bpy
import bmesh
import math
import os

MODELS_DIR = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models"
os.makedirs(MODELS_DIR, exist_ok=True)

def clear_scene():
    """Clears all objects from current scene safely without resetting addon state."""
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def setup_roblox_scene():
    """Configures Blender 3D viewport and units specifically for Roblox Studio (1 Unit = 1 Stud)."""
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0
    scene.unit_settings.length_unit = 'METERS' # 1m in Blender = 1 Stud in Roblox

def apply_transforms(obj):
    """Applies location, rotation and scale transforms to bake mesh geometry."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

def validate_and_export(obj, out_path, format="OBJ"):
    """
    Validates polycount and exports model according to Roblox standards:
    - Forward axis: -Z
    - Up axis: +Y
    - Max triangles: 21,000
    """
    apply_transforms(obj)
    
    # Calculate triangle count
    mesh = obj.data
    tri_count = sum(len(p.vertices) - 2 for p in mesh.polygons)
    print(f"📦 [Roblox Export] Object: {obj.name} | Tris: {tri_count} | Path: {out_path}")
    
    if tri_count > 21000:
        print(f"⚠️ WARNING: {obj.name} has {tri_count} tris which exceeds Roblox's 21,000 limit!")

    if format.upper() == "OBJ":
        bpy.ops.wm.obj_export(
            filepath=out_path,
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True
        )
    elif format.upper() == "FBX":
        bpy.ops.export_scene.fbx(
            filepath=out_path,
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            apply_scale_options='FBX_SCALE_ALL',
            bake_space_transform=True
        )

# ==============================================================================
# Procedural 3D Generators for Starter Assets (Unified GamePalette Atlas)
# ==============================================================================

PALETTE_PATH = os.path.join(MODELS_DIR, "palette.png")
UV_MAP_PATH = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\palette_uv_map.json"

COLOR_UV_MAP = {}
if os.path.exists(UV_MAP_PATH):
    import json
    with open(UV_MAP_PATH, "r", encoding="utf-8") as f:
        COLOR_UV_MAP = json.load(f)

def get_or_create_palette_mat():
    """Creates/retrieves single GamePalette material using palette.png texture."""
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
    bsdf.inputs['Roughness'].default_value = 0.7
    
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

def assign_mesh_uv_color(obj, color_name):
    """Maps all UV vertices of the object to the center coordinate of named palette color."""
    if color_name not in COLOR_UV_MAP:
        return
    u = COLOR_UV_MAP[color_name]["u"]
    v = COLOR_UV_MAP[color_name]["v"]
    
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active.data
    for loop in uv_layer:
        loop.uv = (u, v)

def set_bmesh_uv(bm, faces, color_name):
    """Maps all UV loops in given bmesh faces to the center of named palette color."""
    if color_name not in COLOR_UV_MAP:
        return
    u = COLOR_UV_MAP[color_name]["u"]
    v = COLOR_UV_MAP[color_name]["v"]
    uv_layer = bm.loops.layers.uv.verify()
    for f in faces:
        for loop in f.loops:
            loop[uv_layer].uv = (u, v)

def add_box_bm(bm, x0, x1, y0, y1, z0, z1, col_name=None):
    """Creates an axis-aligned box in bmesh and optionally assigns palette UV color."""
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
    return f

def export_modular_model(root, parts, model_name, target_dirs=None):
    """
    Standard baked single-mesh exporter with multi-part source preservation:
    1. Saves multi-part source scene to assets/models/sources/{model_name}_source.blend.
    2. Joins all child parts into a single monolithic Mesh object named model_name.capitalize().
    3. Applies Flat Shading, transforms, and GamePalette material with UV mapping on palette.png.
    4. Exports single-part .blend, .fbx, .obj to all target directories.
    """
    if target_dirs is None:
        target_dirs = [MODELS_DIR]
        
    sources_dir = os.path.join(MODELS_DIR, "sources")
    os.makedirs(sources_dir, exist_ok=True)
    
    mat = get_or_create_palette_mat()
    
    # 1. Setup multi-part hierarchy for source file
    if root is not None:
        for p in parts:
            p.parent = root
            p.data.materials.clear()
            p.data.materials.append(mat)
            bpy.context.view_layer.objects.active = p
            p.select_set(True)
            bpy.ops.object.shade_flat()
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
            p.select_set(False)
            
        # Save multi-part source project
        source_blend = os.path.join(sources_dir, f"{model_name}_source.blend")
        bpy.ops.wm.save_as_mainfile(filepath=source_blend)
        
        # Unparent parts and remove root empty before joining
        for p in parts:
            p.parent = None
            bpy.context.view_layer.objects.active = p
            p.select_set(True)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            p.select_set(False)
        bpy.data.objects.remove(root, do_unlink=True)
    else:
        for p in parts:
            p.data.materials.clear()
            p.data.materials.append(mat)
            bpy.context.view_layer.objects.active = p
            p.select_set(True)
            bpy.ops.object.shade_flat()
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            p.select_set(False)
        source_blend = os.path.join(sources_dir, f"{model_name}_source.blend")
        bpy.ops.wm.save_as_mainfile(filepath=source_blend)

    # 2. Join all parts into a SINGLE Mesh object
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
        
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
        
    single_mesh = bpy.context.view_layer.objects.active
    capitalized_name = model_name.replace("_", " ").title().replace(" ", "")
    single_mesh.name = capitalized_name
    # Ensure UV map is named "UVMap" for standard Roblox compatibility
    if single_mesh.data.uv_layers.active:
        single_mesh.data.uv_layers.active.name = "UVMap"
    elif len(single_mesh.data.uv_layers) > 0:
        single_mesh.data.uv_layers[0].name = "UVMap"

    # Ensure material and flat shading
    single_mesh.data.materials.clear()
    single_mesh.data.materials.append(mat)
    bpy.ops.object.shade_flat()
    apply_transforms(single_mesh)
    
    # Calculate triangle count
    tri_count = sum(len(p.vertices) - 2 for p in single_mesh.data.polygons)

    # 3. Export single-mesh .blend, .fbx, .obj to target directories
    for d in target_dirs:
        os.makedirs(d, exist_ok=True)
        # Save baked .blend
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(d, f"{model_name}.blend"))
        
        bpy.ops.object.select_all(action='DESELECT')
        single_mesh.select_set(True)
        bpy.context.view_layer.objects.active = single_mesh
        
        bpy.ops.export_scene.fbx(
            filepath=os.path.join(d, f"{model_name}.fbx"),
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            global_scale=1.0,
            apply_unit_scale=True,
            apply_scale_options='FBX_SCALE_ALL',
            bake_space_transform=True,
            use_triangles=True,
            mesh_smooth_type='FACE',
            embed_textures=False,
            path_mode='AUTO'
        )
        bpy.ops.wm.obj_export(
            filepath=os.path.join(d, f"{model_name}.obj"),
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True,
            apply_transform=True,
            export_triangulated_mesh=True,
            export_uv=True,
            export_normals=True,
            export_materials=True
        )
    print(f"✅ [Single MeshPart] Exported '{model_name}' (1 object, {tri_count} tris) to {[os.path.basename(d) for d in target_dirs]}")

def finalize_asset(obj, name, out_obj=True, out_fbx=True):
    """Assigns palette material, flat shading, and exports with triangulation for Roblox."""
    mat = get_or_create_palette_mat()
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if obj.data.uv_layers.active:
        obj.data.uv_layers.active.name = "UVMap"
    bpy.ops.object.shade_flat()
    
    if out_obj:
        bpy.ops.wm.obj_export(
            filepath=os.path.join(MODELS_DIR, f"{name}.obj"),
            export_selected_objects=True,
            forward_axis='NEGATIVE_Z',
            up_axis='Y',
            apply_modifiers=True,
            apply_transform=True,
            export_triangulated_mesh=True,
            export_uv=True,
            export_normals=True,
            export_materials=True
        )
    if out_fbx:
        bpy.ops.export_scene.fbx(
            filepath=os.path.join(MODELS_DIR, f"{name}.fbx"),
            use_selection=True,
            axis_forward='-Z',
            axis_up='Y',
            global_scale=1.0,
            apply_unit_scale=True,
            apply_scale_options='FBX_SCALE_ALL',
            bake_space_transform=True,
            use_triangles=True,
            mesh_smooth_type='FACE'
        )

def export_modular_assembly(parts, base_name="spear-1"):
    """
    Exports a modular assembly where all parts remain distinct, named MeshParts inside a SINGLE container file:
    1. Single FBX file containing the hierarchy of separate parts (assets/models/{base_name}.fbx).
    2. Single OBJ file containing all named sub-objects (assets/models/{base_name}.obj).
    - No separate subfolder or component files created.
    - All parts share the unified coordinate pivot at (0, 0, 0).
    - All parts are mapped to the unified GamePalette texture.
    """
    mat = get_or_create_palette_mat()
    
    # 1. Prepare and apply transforms, materials, flat shading for each part
    for p in parts:
        p.data.materials.clear()
        p.data.materials.append(mat)
        bpy.context.view_layer.objects.active = p
        p.select_set(True)
        bpy.ops.object.shade_flat()
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        p.select_set(False)
        
    # 2. Export full multi-object assembly FBX and OBJ (all parts selected together)
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    
    assembly_fbx = os.path.join(MODELS_DIR, f"{base_name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=assembly_fbx,
        use_selection=True,
        axis_forward='-Z',
        axis_up='Y',
        apply_scale_options='FBX_SCALE_ALL',
        bake_space_transform=True
    )
    
    assembly_obj = os.path.join(MODELS_DIR, f"{base_name}.obj")
    bpy.ops.wm.obj_export(
        filepath=assembly_obj,
        export_selected_objects=True,
        forward_axis='NEGATIVE_Z',
        up_axis='Y',
        apply_modifiers=True
    )
    print(f"✅ Multi-Part Asset '{base_name}' exported into single container ({len(parts)} separate objects): {assembly_fbx}")

def create_spear(name="spear-2"):
    """Creates elegant, sculpted stylized low-poly hunting spear matching GAME_ASSETS_CATALOG.md."""
    clear_scene()
    setup_roblox_scene()

    bm = bmesh.new()
    N = 6

    def make_ring(z, r, n=6, rot_offset=0):
        verts = []
        for i in range(n):
            ang = (2 * math.pi * i / n) + rot_offset
            x = r * math.cos(ang)
            y = r * math.sin(ang)
            verts.append(bm.verts.new((x, y, z)))
        return verts

    def bridge_rings(r1, r2):
        faces = []
        n = len(r1)
        for i in range(n):
            i_next = (i + 1) % n
            faces.append(bm.faces.new((r1[i], r1[i_next], r2[i_next], r2[i])))
        return faces

    def set_faces_uv(faces, color_name):
        if color_name not in COLOR_UV_MAP:
            return
        u = COLOR_UV_MAP[color_name]["u"]
        v = COLOR_UV_MAP[color_name]["v"]
        uv_layer = bm.loops.layers.uv.verify()
        for f in faces:
            for loop in f.loops:
                loop[uv_layer].uv = (u, v)

    # 1. BUTT-SPIKE & POMMEL (Z = -1.15 to -0.75)
    v_butt_tip = bm.verts.new((0, 0, -1.15))
    ring_butt_mid = make_ring(-0.96, 0.022, n=N)
    ring_butt_top = make_ring(-0.85, 0.038, n=N)
    
    faces_butt = []
    for i in range(N):
        i_next = (i + 1) % N
        faces_butt.append(bm.faces.new((v_butt_tip, ring_butt_mid[i_next], ring_butt_mid[i])))
    faces_butt.extend(bridge_rings(ring_butt_mid, ring_butt_top))
    set_faces_uv(faces_butt, "slate_light")
    
    # Butt Collar Ring
    ring_butt_collar = make_ring(-0.80, 0.050, n=N)
    ring_butt_collar_top = make_ring(-0.75, 0.042, n=N)
    faces_b_col = bridge_rings(ring_butt_top, ring_butt_collar)
    faces_b_col.extend(bridge_rings(ring_butt_collar, ring_butt_collar_top))
    set_faces_uv(faces_b_col, "iron_band")
    
    # 2. LOWER SHAFT SEGMENT (Z = -0.75 to -0.52)
    ring_shaft_low = make_ring(-0.52, 0.042, n=N)
    faces_low_shaft = bridge_rings(ring_butt_collar_top, ring_shaft_low)
    set_faces_uv(faces_low_shaft, "wood_honey_oak")
    
    # 3. GRIP HANDLE (Z = -0.52 to +0.52, centered at (0,0,0))
    # Lower Ferrule Ring
    ring_g_b1 = make_ring(-0.48, 0.052, n=N)
    ring_g_b2 = make_ring(-0.44, 0.046, n=N)
    faces_g_b = bridge_rings(ring_shaft_low, ring_g_b1)
    faces_g_b.extend(bridge_rings(ring_g_b1, ring_g_b2))
    set_faces_uv(faces_g_b, "copper_bronze")
    
    # Leather Grip Wraps
    ring_g_m1 = make_ring(-0.22, 0.049, n=N, rot_offset=math.pi/12)
    ring_g_m2 = make_ring(0.00, 0.047, n=N)
    ring_g_m3 = make_ring(0.22, 0.049, n=N, rot_offset=math.pi/12)
    ring_g_m4 = make_ring(0.44, 0.046, n=N)
    
    faces_grip = bridge_rings(ring_g_b2, ring_g_m1)
    faces_grip.extend(bridge_rings(ring_g_m1, ring_g_m2))
    faces_grip.extend(bridge_rings(ring_g_m2, ring_g_m3))
    faces_grip.extend(bridge_rings(ring_g_m3, ring_g_m4))
    set_faces_uv(faces_grip, "leather_dark")
    
    # Upper Ferrule Ring
    ring_g_t1 = make_ring(0.48, 0.052, n=N)
    ring_g_t2 = make_ring(0.52, 0.042, n=N)
    faces_g_t = bridge_rings(ring_g_m4, ring_g_t1)
    faces_g_t.extend(bridge_rings(ring_g_t1, ring_g_t2))
    set_faces_uv(faces_g_t, "copper_bronze")
    
    # 4. MAIN SHAFT (Z = 0.52 to 2.80)
    ring_s_m1 = make_ring(1.40, 0.040, n=N)
    ring_s_m2 = make_ring(2.20, 0.038, n=N)
    ring_s_top = make_ring(2.80, 0.036, n=N)
    
    faces_shaft = bridge_rings(ring_g_t2, ring_s_m1)
    faces_shaft.extend(bridge_rings(ring_s_m1, ring_s_m2))
    faces_shaft.extend(bridge_rings(ring_s_m2, ring_s_top))
    set_faces_uv(faces_shaft, "wood_honey_oak")
    
    # 5. NECK LEATHER/TWINE BINDING (Z = 2.80 to 3.15)
    ring_w1 = make_ring(2.92, 0.047, n=N, rot_offset=math.pi/12)
    ring_w2 = make_ring(3.04, 0.049, n=N)
    ring_w3 = make_ring(3.15, 0.045, n=N, rot_offset=math.pi/12)
    
    faces_wrap = bridge_rings(ring_s_top, ring_w1)
    faces_wrap.extend(bridge_rings(ring_w1, ring_w2))
    faces_wrap.extend(bridge_rings(ring_w2, ring_w3))
    set_faces_uv(faces_wrap, "twine_straw")
    
    # 6. STEEL SOCKET COLLAR & BRONZE WINGS (Z = 3.15 to 3.45)
    ring_c_b = make_ring(3.22, 0.054, n=N)
    ring_c_m = make_ring(3.34, 0.050, n=N)
    ring_c_t = make_ring(3.45, 0.042, n=N)
    
    faces_col = bridge_rings(ring_w3, ring_c_b)
    faces_col.extend(bridge_rings(ring_c_b, ring_c_m))
    faces_col.extend(bridge_rings(ring_c_m, ring_c_t))
    set_faces_uv(faces_col, "iron_band")
    
    # Wing Lugs
    wl1 = bm.verts.new((-0.042, 0.010, 3.24))
    wl2 = bm.verts.new((-0.13, 0.006, 3.30))
    wl3 = bm.verts.new((-0.16, 0.0, 3.38))
    wl4 = bm.verts.new((-0.07, 0.0, 3.42))
    wl5 = bm.verts.new((-0.042, -0.010, 3.24))
    wl6 = bm.verts.new((-0.13, -0.006, 3.30))
    
    wr1 = bm.verts.new((0.042, 0.010, 3.24))
    wr2 = bm.verts.new((0.13, 0.006, 3.30))
    wr3 = bm.verts.new((0.16, 0.0, 3.38))
    wr4 = bm.verts.new((0.07, 0.0, 3.42))
    wr5 = bm.verts.new((0.042, -0.010, 3.24))
    wr6 = bm.verts.new((0.13, -0.006, 3.30))
    
    faces_lugs = [
        bm.faces.new((wl1, wl2, wl3, wl4)),
        bm.faces.new((wl4, wl3, wl6, wl5)),
        bm.faces.new((wl1, wl5, wl6, wl2)),
        bm.faces.new((wr4, wr3, wr2, wr1)),
        bm.faces.new((wr5, wr6, wr3, wr4)),
        bm.faces.new((wr2, wr6, wr5, wr1))
    ]
    set_faces_uv(faces_lugs, "copper_bronze")
    
    # 7. HIGH-ELEGANCE SCULPTED LEAF BLADE (Z = 3.45 to 4.92)
    v0_sf = bm.verts.new((0, 0.032, 3.45))
    v0_sb = bm.verts.new((0, -0.032, 3.45))
    v0_el = bm.verts.new((-0.038, 0, 3.45))
    v0_er = bm.verts.new((0.038, 0, 3.45))
    
    v1_sf = bm.verts.new((0, 0.042, 3.65))
    v1_sb = bm.verts.new((0, -0.042, 3.65))
    v1_el = bm.verts.new((-0.10, 0, 3.65))
    v1_er = bm.verts.new((0.10, 0, 3.65))
    
    v2_sf = bm.verts.new((0, 0.040, 3.88))
    v2_sb = bm.verts.new((0, -0.040, 3.88))
    v2_el = bm.verts.new((-0.088, 0, 3.88))
    v2_er = bm.verts.new((0.088, 0, 3.88))
    
    v3_sf = bm.verts.new((0, 0.036, 4.22))
    v3_sb = bm.verts.new((0, -0.036, 4.22))
    v3_el = bm.verts.new((-0.165, 0, 4.22))
    v3_er = bm.verts.new((0.165, 0, 4.22))
    
    v4_sf = bm.verts.new((0, 0.022, 4.60))
    v4_sb = bm.verts.new((0, -0.022, 4.60))
    v4_el = bm.verts.new((-0.075, 0, 4.60))
    v4_er = bm.verts.new((0.075, 0, 4.60))
    
    v5_tip = bm.verts.new((0, 0, 4.92))
    
    # Front Blade Faces
    f_fl0 = bm.faces.new((v0_sf, v0_el, v1_el, v1_sf))
    f_fr0 = bm.faces.new((v0_sf, v1_sf, v1_er, v0_er))
    f_fl1 = bm.faces.new((v1_sf, v1_el, v2_el, v2_sf))
    f_fr1 = bm.faces.new((v1_sf, v2_sf, v2_er, v1_er))
    f_fl2 = bm.faces.new((v2_sf, v2_el, v3_el, v3_sf))
    f_fr2 = bm.faces.new((v2_sf, v3_sf, v3_er, v2_er))
    f_fl3 = bm.faces.new((v3_sf, v3_el, v4_el, v4_sf))
    f_fr3 = bm.faces.new((v3_sf, v4_sf, v4_er, v3_er))
    f_fl4 = bm.faces.new((v4_sf, v4_el, v5_tip))
    f_fr4 = bm.faces.new((v4_sf, v5_tip, v4_er))
    
    # Back Blade Faces
    f_bl0 = bm.faces.new((v0_sb, v1_sb, v1_el, v0_el))
    f_br0 = bm.faces.new((v0_sb, v0_er, v1_er, v1_sb))
    f_bl1 = bm.faces.new((v1_sb, v2_sb, v2_el, v1_el))
    f_br1 = bm.faces.new((v1_sb, v1_er, v2_er, v2_sb))
    f_bl2 = bm.faces.new((v2_sb, v3_sb, v3_el, v2_el))
    f_br2 = bm.faces.new((v2_sb, v2_er, v3_er, v3_sb))
    f_bl3 = bm.faces.new((v3_sb, v4_sb, v4_el, v3_el))
    f_br3 = bm.faces.new((v3_sb, v3_er, v4_er, v4_sb))
    f_bl4 = bm.faces.new((v4_sb, v5_tip, v4_el))
    f_br4 = bm.faces.new((v4_sb, v4_er, v5_tip))
    
    # Cap between collar top and blade base
    cap_faces = []
    base_verts = [v0_el, v0_sf, v0_er, v0_sb]
    for i in range(N):
        i_next = (i + 1) % N
        bv1 = base_verts[i % 4]
        bv2 = base_verts[(i + 1) % 4]
        try:
            f = bm.faces.new((ring_c_t[i], ring_c_t[i_next], bv2, bv1))
            cap_faces.append(f)
        except Exception:
            pass
    set_faces_uv(cap_faces, "iron_band")
    
    # Cutting bevel shading
    set_faces_uv([f_fl0, f_fl1, f_fl2, f_fl3, f_fl4], "slate_light")
    set_faces_uv([f_fr0, f_fr1, f_fr2, f_fr3, f_fr4], "steel_light")
    set_faces_uv([f_bl0, f_bl1, f_bl2, f_bl3, f_bl4], "slate_light")
    set_faces_uv([f_br0, f_br1, f_br2, f_br3, f_br4], "steel_light")

    bm.normal_update()

    mesh = bpy.data.meshes.new("SpearMesh")
    bm.to_mesh(mesh)
    bm.free()

    spear_obj = bpy.data.objects.new("Spear", mesh)
    bpy.context.collection.objects.link(spear_obj)
    
    finalize_asset(spear_obj, name)
    finalize_asset(spear_obj, "spear-2")

def create_torch():
    """Creates stylized survival wooden torch with faceted flame."""
    clear_scene()
    setup_roblox_scene()
    
    # 1. Stick
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.08, depth=2.4, location=(0, 0, 0.8))
    stick = bpy.context.active_object
    stick.name = "Stick"
    assign_mesh_uv_color(stick, "wood_cedar")
    
    # 2. Cloth Head Wrap
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.18, depth=0.6, location=(0, 0, 1.9))
    head = bpy.context.active_object
    head.name = "HeadWrap"
    assign_mesh_uv_color(head, "twine_straw")

    # 3. Faceted Low-Poly Flame
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.22, radius2=0.02, depth=0.8, location=(0, 0, 2.5))
    flame = bpy.context.active_object
    flame.name = "Flame"
    assign_mesh_uv_color(flame, "flame_orange")
    
    parts = [stick, head, flame]
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = stick
    bpy.ops.object.join()
    
    torch = bpy.context.active_object
    torch.name = "Torch"
    finalize_asset(torch, "torch")

def create_chest():
    """Creates gold-standard multi-part supply chest with arched lid, metal bands, golden lock, and side handles."""
    clear_scene()
    setup_roblox_scene()
    
    def add_box_bm(bm, x0, x1, y0, y1, z0, z1, col_name):
        v = [
            bm.verts.new((x0, y0, z0)),
            bm.verts.new((x1, y0, z0)),
            bm.verts.new((x1, y1, z0)),
            bm.verts.new((x0, y1, z0)),
            bm.verts.new((x0, y0, z1)),
            bm.verts.new((x1, y0, z1)),
            bm.verts.new((x1, y1, z1)),
            bm.verts.new((x0, y1, z1)),
        ]
        f = [
            bm.faces.new((v[0], v[1], v[2], v[3])),
            bm.faces.new((v[4], v[7], v[6], v[5])),
            bm.faces.new((v[0], v[4], v[5], v[1])),
            bm.faces.new((v[2], v[6], v[7], v[3])),
            bm.faces.new((v[3], v[7], v[4], v[0])),
            bm.faces.new((v[1], v[5], v[6], v[2])),
        ]
        if col_name in COLOR_UV_MAP:
            u, v_coord = COLOR_UV_MAP[col_name]["u"], COLOR_UV_MAP[col_name]["v"]
            uv_layer = bm.loops.layers.uv.verify()
            for face in f:
                for loop in face.loops:
                    loop[uv_layer].uv = (u, v_coord)
        return f

    # 1. Base Box
    bm_base = bmesh.new()
    add_box_bm(bm_base, -1.20, 1.20, -0.80, 0.80, 0.04, 1.15, "wood_honey_oak")
    add_box_bm(bm_base, -1.18, 1.18, -0.805, -0.795, 0.40, 0.43, "wood_cedar")
    add_box_bm(bm_base, -1.18, 1.18, -0.805, -0.795, 0.77, 0.80, "wood_cedar")
    bm_base.normal_update()
    m_base = bpy.data.meshes.new("ChestBaseMesh")
    bm_base.to_mesh(m_base)
    bm_base.free()
    obj_base = bpy.data.objects.new("ChestBase", m_base)
    bpy.context.collection.objects.link(obj_base)

    # 2. Arched Lid
    bm_lid = bmesh.new()
    arch_pts = [
        (-0.84, 1.15), (-0.72, 1.48), (-0.38, 1.74),
        ( 0.38, 1.74), ( 0.72, 1.48), ( 0.84, 1.15)
    ]
    v_l = [bm_lid.verts.new((-1.24, y, z)) for (y, z) in arch_pts]
    v_r = [bm_lid.verts.new(( 1.24, y, z)) for (y, z) in arch_pts]
    faces_lid = [
        bm_lid.faces.new((v_l[0], v_r[0], v_r[1], v_l[1])),
        bm_lid.faces.new((v_l[1], v_r[1], v_r[2], v_l[2])),
        bm_lid.faces.new((v_l[2], v_r[2], v_r[3], v_l[3])),
        bm_lid.faces.new((v_l[3], v_r[3], v_r[4], v_l[4])),
        bm_lid.faces.new((v_l[4], v_r[4], v_r[5], v_l[5])),
        bm_lid.faces.new((v_l[5], v_r[5], v_r[0], v_l[0])),
    ]
    f_cap_l = bm_lid.faces.new(list(reversed(v_l)))
    f_cap_r = bm_lid.faces.new(v_r)
    
    uv_layer = bm_lid.loops.layers.uv.verify()
    u_h, v_h = COLOR_UV_MAP["wood_honey_oak"]["u"], COLOR_UV_MAP["wood_honey_oak"]["v"]
    for f in faces_lid:
        for loop in f.loops: loop[uv_layer].uv = (u_h, v_h)
    u_c, v_c = COLOR_UV_MAP["wood_cedar"]["u"], COLOR_UV_MAP["wood_cedar"]["v"]
    for f in [f_cap_l, f_cap_r]:
        for loop in f.loops: loop[uv_layer].uv = (u_c, v_c)

    bm_lid.normal_update()
    m_lid = bpy.data.meshes.new("ChestLidMesh")
    bm_lid.to_mesh(m_lid)
    bm_lid.free()
    obj_lid = bpy.data.objects.new("ChestLid", m_lid)
    bpy.context.collection.objects.link(obj_lid)

    # 3. Base Bands & Corner Brackets
    bm_bb = bmesh.new()
    add_box_bm(bm_bb, -1.24, 1.24, -0.84, 0.84, 0.0, 0.14, "cast_iron")
    add_box_bm(bm_bb, -1.23, 1.23, -0.83, 0.83, 1.07, 1.15, "cast_iron")
    cs = 0.12
    add_box_bm(bm_bb, -1.23, -1.23 + cs, -0.83, -0.83 + cs, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb,  1.23 - cs,  1.23, -0.83, -0.83 + cs, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb, -1.23, -1.23 + cs,  0.83 - cs,  0.83, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb,  1.23 - cs,  1.23,  0.83 - cs,  0.83, 0.14, 1.07, "iron_band")
    sw, st = 0.10, 0.02
    add_box_bm(bm_bb, -0.62 - sw/2, -0.62 + sw/2, -0.80 - st, -0.80, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb,  0.62 - sw/2,  0.62 + sw/2, -0.80 - st, -0.80, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb, -0.62 - sw/2, -0.62 + sw/2,  0.80,  0.80 + st, 0.14, 1.07, "iron_band")
    add_box_bm(bm_bb,  0.62 - sw/2,  0.62 + sw/2,  0.80,  0.80 + st, 0.14, 1.07, "iron_band")
    rv = 0.03
    for sx in [-0.62, 0.62]:
        for sz in [0.30, 0.60, 0.90]:
            add_box_bm(bm_bb, sx - rv/2, sx + rv/2, -0.825, -0.815, sz - rv/2, sz + rv/2, "steel_light")
    bm_bb.normal_update()
    m_bb = bpy.data.meshes.new("BaseBandsMesh")
    bm_bb.to_mesh(m_bb)
    bm_bb.free()
    obj_bb = bpy.data.objects.new("BaseBands", m_bb)
    bpy.context.collection.objects.link(obj_bb)

    # 4. Lid Bands
    bm_lb = bmesh.new()
    def add_arch_strap_bm(bm, cx, w, thickness, col_name):
        x_min, x_max = cx - w/2, cx + w/2
        v_in_l, v_in_r, v_out_l, v_out_r = [], [], [], []
        for (y, z) in arch_pts:
            ny = y / 0.84 if abs(y) > 0.01 else 0.0
            nz = (z - 1.15) / 0.59
            mag = math.sqrt(ny*ny + nz*nz)
            oy = (ny / mag) * thickness if mag > 0.001 else 0
            oz = (nz / mag) * thickness if mag > 0.001 else thickness
            v_in_l.append(bm.verts.new((x_min, y, z)))
            v_in_r.append(bm.verts.new((x_max, y, z)))
            v_out_l.append(bm.verts.new((x_min, y + oy, z + oz)))
            v_out_r.append(bm.verts.new((x_max, y + oy, z + oz)))
        f_list = []
        for i in range(len(arch_pts) - 1):
            f_list.append(bm.faces.new((v_out_l[i], v_out_r[i], v_out_r[i+1], v_out_l[i+1])))
            f_list.append(bm.faces.new((v_in_l[i], v_out_l[i], v_out_l[i+1], v_in_l[i+1])))
            f_list.append(bm.faces.new((v_out_r[i], v_in_r[i], v_in_r[i+1], v_out_r[i+1])))
        f_list.append(bm.faces.new((v_in_l[0], v_in_r[0], v_out_r[0], v_out_l[0])))
        f_list.append(bm.faces.new((v_out_l[-1], v_out_r[-1], v_in_r[-1], v_in_l[-1])))
        if col_name in COLOR_UV_MAP:
            u_s, v_s = COLOR_UV_MAP[col_name]["u"], COLOR_UV_MAP[col_name]["v"]
            uv_l = bm.loops.layers.uv.verify()
            for fa in f_list:
                for loop in fa.loops: loop[uv_l].uv = (u_s, v_s)

    add_arch_strap_bm(bm_lb, -0.62, sw, 0.025, "iron_band")
    add_arch_strap_bm(bm_lb,  0.62, sw, 0.025, "iron_band")
    add_arch_strap_bm(bm_lb, -1.24, 0.05, 0.02, "cast_iron")
    add_arch_strap_bm(bm_lb,  1.24, 0.05, 0.02, "cast_iron")
    add_box_bm(bm_lb, -1.25, 1.25, -0.86, -0.82, 1.14, 1.20, "cast_iron")
    bm_lb.normal_update()
    m_lb = bpy.data.meshes.new("LidBandsMesh")
    bm_lb.to_mesh(m_lb)
    bm_lb.free()
    obj_lb = bpy.data.objects.new("LidBands", m_lb)
    bpy.context.collection.objects.link(obj_lb)

    # 5. Latch & Padlock
    bm_lock = bmesh.new()
    add_box_bm(bm_lock, -0.16, 0.16, -0.84, -0.81, 0.94, 1.26, "cast_iron")
    add_box_bm(bm_lock, -0.11, 0.11, -0.86, -0.83, 1.08, 1.28, "iron_band")
    add_box_bm(bm_lock, -0.18, 0.18, -0.92, -0.85, 0.86, 1.10, "gold_pure")
    add_box_bm(bm_lock, -0.04, 0.04, -0.925, -0.915, 0.92, 1.02, "cast_iron")
    add_box_bm(bm_lock, -0.12, 0.12, -0.89, -0.86, 1.10, 1.18, "copper_bronze")
    bm_lock.normal_update()
    m_lock = bpy.data.meshes.new("LatchMesh")
    bm_lock.to_mesh(m_lock)
    bm_lock.free()
    obj_lock = bpy.data.objects.new("Latch", m_lock)
    bpy.context.collection.objects.link(obj_lock)

    # 6. Handles
    bm_h = bmesh.new()
    add_box_bm(bm_h, -1.23, -1.205, -0.20, 0.20, 0.52, 0.74, "cast_iron")
    add_box_bm(bm_h, -1.32, -1.23, -0.16, -0.10, 0.44, 0.68, "copper_bronze")
    add_box_bm(bm_h, -1.32, -1.23,  0.10,  0.16, 0.44, 0.68, "copper_bronze")
    add_box_bm(bm_h, -1.32, -1.23, -0.16,  0.16, 0.40, 0.46, "copper_bronze")
    add_box_bm(bm_h, 1.205, 1.23, -0.20, 0.20, 0.52, 0.74, "cast_iron")
    add_box_bm(bm_h, 1.23, 1.32, -0.16, -0.10, 0.44, 0.68, "copper_bronze")
    add_box_bm(bm_h, 1.23, 1.32,  0.10,  0.16, 0.44, 0.68, "copper_bronze")
    add_box_bm(bm_h, 1.23, 1.32, -0.16,  0.16, 0.40, 0.46, "copper_bronze")
    bm_h.normal_update()
    m_h = bpy.data.meshes.new("HandlesMesh")
    bm_h.to_mesh(m_h)
    bm_h.free()
    obj_h = bpy.data.objects.new("Handles", m_h)
    bpy.context.collection.objects.link(obj_h)

    # 7. Hinges
    bm_hinge = bmesh.new()
    add_box_bm(bm_hinge, -0.62 - sw/2, -0.62 + sw/2, 0.80, 0.84, 1.08, 1.22, "cast_iron")
    add_box_bm(bm_hinge,  0.62 - sw/2,  0.62 + sw/2, 0.80, 0.84, 1.08, 1.22, "cast_iron")
    bm_hinge.normal_update()
    m_hinge = bpy.data.meshes.new("HingesMesh")
    bm_hinge.to_mesh(m_hinge)
    bm_hinge.free()
    obj_hinge = bpy.data.objects.new("Hinges", m_hinge)
    bpy.context.collection.objects.link(obj_hinge)

    # Root Container & Export
    root_empty = bpy.data.objects.new("Chest", None)
    root_empty.location = (0, 0, 0)
    bpy.context.collection.objects.link(root_empty)
    
    parts = [obj_base, obj_lid, obj_bb, obj_lb, obj_lock, obj_h, obj_hinge]
    export_modular_model(root_empty, parts, "chest", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_parts_chest():
    """Creates gold-standard industrial parts chest with ice_deep / tech_cyan body, gunmetal bands, and glowing cyber lock."""
    clear_scene()
    setup_roblox_scene()
    
    def add_box_bm(bm, x0, x1, y0, y1, z0, z1, col_name):
        v = [
            bm.verts.new((x0, y0, z0)),
            bm.verts.new((x1, y0, z0)),
            bm.verts.new((x1, y1, z0)),
            bm.verts.new((x0, y1, z0)),
            bm.verts.new((x0, y0, z1)),
            bm.verts.new((x1, y0, z1)),
            bm.verts.new((x1, y1, z1)),
            bm.verts.new((x0, y1, z1)),
        ]
        f = [
            bm.faces.new((v[0], v[1], v[2], v[3])),
            bm.faces.new((v[4], v[7], v[6], v[5])),
            bm.faces.new((v[0], v[4], v[5], v[1])),
            bm.faces.new((v[2], v[6], v[7], v[3])),
            bm.faces.new((v[3], v[7], v[4], v[0])),
            bm.faces.new((v[1], v[5], v[6], v[2])),
        ]
        if col_name in COLOR_UV_MAP:
            u, v_coord = COLOR_UV_MAP[col_name]["u"], COLOR_UV_MAP[col_name]["v"]
            uv_layer = bm.loops.layers.uv.verify()
            for face in f:
                for loop in face.loops:
                    loop[uv_layer].uv = (u, v_coord)
        return f

    # 1. Base Box (High-tech Industrial Alloy: ice_deep body with tech_cyan accent lines)
    bm_base = bmesh.new()
    add_box_bm(bm_base, -1.20, 1.20, -0.80, 0.80, 0.04, 1.15, "ice_deep")
    add_box_bm(bm_base, -1.18, 1.18, -0.805, -0.795, 0.40, 0.43, "tech_cyan")
    add_box_bm(bm_base, -1.18, 1.18, -0.805, -0.795, 0.77, 0.80, "tech_cyan")
    bm_base.normal_update()
    m_base = bpy.data.meshes.new("ChestBaseMesh")
    bm_base.to_mesh(m_base)
    bm_base.free()
    obj_base = bpy.data.objects.new("ChestBase", m_base)
    bpy.context.collection.objects.link(obj_base)

    # 2. Arched Lid (ice_deep with gunmetal end caps)
    bm_lid = bmesh.new()
    arch_pts = [
        (-0.84, 1.15), (-0.72, 1.48), (-0.38, 1.74),
        ( 0.38, 1.74), ( 0.72, 1.48), ( 0.84, 1.15)
    ]
    v_l = [bm_lid.verts.new((-1.24, y, z)) for (y, z) in arch_pts]
    v_r = [bm_lid.verts.new(( 1.24, y, z)) for (y, z) in arch_pts]
    faces_lid = [
        bm_lid.faces.new((v_l[0], v_r[0], v_r[1], v_l[1])),
        bm_lid.faces.new((v_l[1], v_r[1], v_r[2], v_l[2])),
        bm_lid.faces.new((v_l[2], v_r[2], v_r[3], v_l[3])),
        bm_lid.faces.new((v_l[3], v_r[3], v_r[4], v_l[4])),
        bm_lid.faces.new((v_l[4], v_r[4], v_r[5], v_l[5])),
        bm_lid.faces.new((v_l[5], v_r[5], v_r[0], v_l[0])),
    ]
    f_cap_l = bm_lid.faces.new(list(reversed(v_l)))
    f_cap_r = bm_lid.faces.new(v_r)
    
    uv_layer = bm_lid.loops.layers.uv.verify()
    u_h, v_h = COLOR_UV_MAP["ice_deep"]["u"], COLOR_UV_MAP["ice_deep"]["v"]
    for f in faces_lid:
        for loop in f.loops: loop[uv_layer].uv = (u_h, v_h)
    u_c, v_c = COLOR_UV_MAP["gunmetal"]["u"], COLOR_UV_MAP["gunmetal"]["v"]
    for f in [f_cap_l, f_cap_r]:
        for loop in f.loops: loop[uv_layer].uv = (u_c, v_c)

    bm_lid.normal_update()
    m_lid = bpy.data.meshes.new("ChestLidMesh")
    bm_lid.to_mesh(m_lid)
    bm_lid.free()
    obj_lid = bpy.data.objects.new("ChestLid", m_lid)
    bpy.context.collection.objects.link(obj_lid)

    # 3. Base Bands & Corner Brackets (Gunmetal & Cast Iron with Glowing Cyan Rivets)
    bm_bb = bmesh.new()
    add_box_bm(bm_bb, -1.24, 1.24, -0.84, 0.84, 0.0, 0.14, "gunmetal")
    add_box_bm(bm_bb, -1.23, 1.23, -0.83, 0.83, 1.07, 1.15, "gunmetal")
    cs = 0.12
    add_box_bm(bm_bb, -1.23, -1.23 + cs, -0.83, -0.83 + cs, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb,  1.23 - cs,  1.23, -0.83, -0.83 + cs, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb, -1.23, -1.23 + cs,  0.83 - cs,  0.83, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb,  1.23 - cs,  1.23,  0.83 - cs,  0.83, 0.14, 1.07, "cast_iron")
    sw, st = 0.10, 0.02
    add_box_bm(bm_bb, -0.62 - sw/2, -0.62 + sw/2, -0.80 - st, -0.80, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb,  0.62 - sw/2,  0.62 + sw/2, -0.80 - st, -0.80, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb, -0.62 - sw/2, -0.62 + sw/2,  0.80,  0.80 + st, 0.14, 1.07, "cast_iron")
    add_box_bm(bm_bb,  0.62 - sw/2,  0.62 + sw/2,  0.80,  0.80 + st, 0.14, 1.07, "cast_iron")
    rv = 0.03
    for sx in [-0.62, 0.62]:
        for sz in [0.30, 0.60, 0.90]:
            add_box_bm(bm_bb, sx - rv/2, sx + rv/2, -0.825, -0.815, sz - rv/2, sz + rv/2, "neon_cyan_glow")
    bm_bb.normal_update()
    m_bb = bpy.data.meshes.new("BaseBandsMesh")
    bm_bb.to_mesh(m_bb)
    bm_bb.free()
    obj_bb = bpy.data.objects.new("BaseBands", m_bb)
    bpy.context.collection.objects.link(obj_bb)

    # 4. Lid Bands (Cast Iron / Gunmetal Arched Straps)
    bm_lb = bmesh.new()
    def add_arch_strap_bm(bm, cx, w, thickness, col_name):
        x_min, x_max = cx - w/2, cx + w/2
        v_in_l, v_in_r, v_out_l, v_out_r = [], [], [], []
        for (y, z) in arch_pts:
            ny = y / 0.84 if abs(y) > 0.01 else 0.0
            nz = (z - 1.15) / 0.59
            mag = math.sqrt(ny*ny + nz*nz)
            oy = (ny / mag) * thickness if mag > 0.001 else 0
            oz = (nz / mag) * thickness if mag > 0.001 else thickness
            v_in_l.append(bm.verts.new((x_min, y, z)))
            v_in_r.append(bm.verts.new((x_max, y, z)))
            v_out_l.append(bm.verts.new((x_min, y + oy, z + oz)))
            v_out_r.append(bm.verts.new((x_max, y + oy, z + oz)))
        f_list = []
        for i in range(len(arch_pts) - 1):
            f_list.append(bm.faces.new((v_out_l[i], v_out_r[i], v_out_r[i+1], v_out_l[i+1])))
            f_list.append(bm.faces.new((v_in_l[i], v_out_l[i], v_out_l[i+1], v_in_l[i+1])))
            f_list.append(bm.faces.new((v_out_r[i], v_in_r[i], v_in_r[i+1], v_out_r[i+1])))
        f_list.append(bm.faces.new((v_in_l[0], v_in_r[0], v_out_r[0], v_out_l[0])))
        f_list.append(bm.faces.new((v_out_l[-1], v_out_r[-1], v_in_r[-1], v_in_l[-1])))
        if col_name in COLOR_UV_MAP:
            u_s, v_s = COLOR_UV_MAP[col_name]["u"], COLOR_UV_MAP[col_name]["v"]
            uv_l = bm.loops.layers.uv.verify()
            for fa in f_list:
                for loop in fa.loops: loop[uv_l].uv = (u_s, v_s)

    add_arch_strap_bm(bm_lb, -0.62, sw, 0.025, "cast_iron")
    add_arch_strap_bm(bm_lb,  0.62, sw, 0.025, "cast_iron")
    add_arch_strap_bm(bm_lb, -1.24, 0.05, 0.02, "gunmetal")
    add_arch_strap_bm(bm_lb,  1.24, 0.05, 0.02, "gunmetal")
    add_box_bm(bm_lb, -1.25, 1.25, -0.86, -0.82, 1.14, 1.20, "gunmetal")
    bm_lb.normal_update()
    m_lb = bpy.data.meshes.new("LidBandsMesh")
    bm_lb.to_mesh(m_lb)
    bm_lb.free()
    obj_lb = bpy.data.objects.new("LidBands", m_lb)
    bpy.context.collection.objects.link(obj_lb)

    # 5. Latch & Tech Electronic Lock
    bm_lock = bmesh.new()
    add_box_bm(bm_lock, -0.16, 0.16, -0.84, -0.81, 0.94, 1.26, "gunmetal")
    add_box_bm(bm_lock, -0.11, 0.11, -0.86, -0.83, 1.08, 1.28, "cast_iron")
    add_box_bm(bm_lock, -0.18, 0.18, -0.92, -0.85, 0.86, 1.10, "tech_cyan")
    add_box_bm(bm_lock, -0.05, 0.05, -0.925, -0.915, 0.92, 1.02, "neon_cyan_glow")
    add_box_bm(bm_lock, -0.12, 0.12, -0.89, -0.86, 1.10, 1.18, "steel_light")
    bm_lock.normal_update()
    m_lock = bpy.data.meshes.new("LatchMesh")
    bm_lock.to_mesh(m_lock)
    bm_lock.free()
    obj_lock = bpy.data.objects.new("Latch", m_lock)
    bpy.context.collection.objects.link(obj_lock)

    # 6. Handles (Industrial Heavy Steel)
    bm_h = bmesh.new()
    add_box_bm(bm_h, -1.23, -1.205, -0.20, 0.20, 0.52, 0.74, "gunmetal")
    add_box_bm(bm_h, -1.32, -1.23, -0.16, -0.10, 0.44, 0.68, "steel_light")
    add_box_bm(bm_h, -1.32, -1.23,  0.10,  0.16, 0.44, 0.68, "steel_light")
    add_box_bm(bm_h, -1.32, -1.23, -0.16,  0.16, 0.40, 0.46, "steel_light")
    add_box_bm(bm_h, 1.205, 1.23, -0.20, 0.20, 0.52, 0.74, "gunmetal")
    add_box_bm(bm_h, 1.23, 1.32, -0.16, -0.10, 0.44, 0.68, "steel_light")
    add_box_bm(bm_h, 1.23, 1.32,  0.10,  0.16, 0.44, 0.68, "steel_light")
    add_box_bm(bm_h, 1.23, 1.32, -0.16,  0.16, 0.40, 0.46, "steel_light")
    bm_h.normal_update()
    m_h = bpy.data.meshes.new("HandlesMesh")
    bm_h.to_mesh(m_h)
    bm_h.free()
    obj_h = bpy.data.objects.new("Handles", m_h)
    bpy.context.collection.objects.link(obj_h)

    # 7. Hinges
    bm_hinge = bmesh.new()
    add_box_bm(bm_hinge, -0.62 - sw/2, -0.62 + sw/2, 0.80, 0.84, 1.08, 1.22, "gunmetal")
    add_box_bm(bm_hinge,  0.62 - sw/2,  0.62 + sw/2, 0.80, 0.84, 1.08, 1.22, "gunmetal")
    bm_hinge.normal_update()
    m_hinge = bpy.data.meshes.new("HingesMesh")
    bm_hinge.to_mesh(m_hinge)
    bm_hinge.free()
    obj_hinge = bpy.data.objects.new("Hinges", m_hinge)
    bpy.context.collection.objects.link(obj_hinge)

    # Root Container & Export
    root_empty = bpy.data.objects.new("Chest_Parts", None)
    root_empty.location = (0, 0, 0)
    bpy.context.collection.objects.link(root_empty)
    
    parts = [obj_base, obj_lid, obj_bb, obj_lb, obj_lock, obj_h, obj_hinge]
    export_modular_model(root_empty, parts, "chest_parts", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_campfire():
    """Creates stylized survival campfire with stones ring, crossed logs, glowing embers and faceted flame."""
    clear_scene()
    setup_roblox_scene()
    
    def add_box_bm(bm, x0, x1, y0, y1, z0, z1, col_name):
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
        if col_name in COLOR_UV_MAP:
            u, v_coord = COLOR_UV_MAP[col_name]["u"], COLOR_UV_MAP[col_name]["v"]
            uv_layer = bm.loops.layers.uv.verify()
            for face in f:
                for loop in face.loops: loop[uv_layer].uv = (u, v_coord)
        return f

    # 1. Stones Ring
    bm_stones = bmesh.new()
    stone_cols = ["stone_slate", "stone_dark", "slate_light", "stone_slate", "stone_dark", "slate_light"]
    for i in range(6):
        ang = i * (math.pi / 3) + 0.2
        r = 1.05
        cx, cy = r * math.cos(ang), r * math.sin(ang)
        sx, sy, sz = 0.26, 0.22, 0.18
        add_box_bm(bm_stones, cx - sx, cx + sx, cy - sy, cy + sy, 0.0, sz * 2, stone_cols[i])
    bm_stones.normal_update()
    m_stones = bpy.data.meshes.new("CampfireStonesMesh")
    bm_stones.to_mesh(m_stones)
    bm_stones.free()
    obj_stones = bpy.data.objects.new("FireRing", m_stones)
    bpy.context.collection.objects.link(obj_stones)

    # 2. Crossed Wood Logs
    bm_logs = bmesh.new()
    log_angles = [0.4, 0.4 + math.pi/2, 0.4 + math.pi, 0.4 + 3*math.pi/2]
    for i, la in enumerate(log_angles):
        cos_a, sin_a = math.cos(la), math.sin(la)
        r_out, r_in = 0.85, 0.10
        x0, y0, z0 = r_out * cos_a, r_out * sin_a, 0.08
        x1, y1, z1 = r_in * cos_a, r_in * sin_a, 0.45
        w = 0.11
        nx, ny = -sin_a * w, cos_a * w
        v_out_bl = bm_logs.verts.new((x0 + nx, y0 + ny, z0))
        v_out_br = bm_logs.verts.new((x0 - nx, y0 - ny, z0))
        v_out_tl = bm_logs.verts.new((x0 + nx, y0 + ny, z0 + w*1.8))
        v_out_tr = bm_logs.verts.new((x0 - nx, y0 - ny, z0 + w*1.8))
        v_in_bl = bm_logs.verts.new((x1 + nx*0.8, y1 + ny*0.8, z1))
        v_in_br = bm_logs.verts.new((x1 - nx*0.8, y1 - ny*0.8, z1))
        v_in_tl = bm_logs.verts.new((x1 + nx*0.8, y1 + ny*0.8, z1 + w*1.4))
        v_in_tr = bm_logs.verts.new((x1 - nx*0.8, y1 - ny*0.8, z1 + w*1.4))
        faces_log = [
            bm_logs.faces.new((v_out_bl, v_out_br, v_in_br, v_in_bl)),
            bm_logs.faces.new((v_out_tl, v_in_tl, v_in_tr, v_out_tr)),
            bm_logs.faces.new((v_out_bl, v_in_bl, v_in_tl, v_out_tl)),
            bm_logs.faces.new((v_out_br, v_out_tr, v_in_tr, v_in_br)),
        ]
        f_cap_out = bm_logs.faces.new((v_out_bl, v_out_tl, v_out_tr, v_out_br))
        f_cap_in = bm_logs.faces.new((v_in_bl, v_in_br, v_in_tr, v_in_tl))
        set_bmesh_uv(bm_logs, faces_log, "wood_cedar" if i % 2 == 0 else "wood_honey_oak")
        set_bmesh_uv(bm_logs, [f_cap_out, f_cap_in], "wood_pine")
    bm_logs.normal_update()
    m_logs = bpy.data.meshes.new("CampfireLogsMesh")
    bm_logs.to_mesh(m_logs)
    bm_logs.free()
    obj_logs = bpy.data.objects.new("FireLogs", m_logs)
    bpy.context.collection.objects.link(obj_logs)

    # 3. Glowing Embers Bed
    bm_embers = bmesh.new()
    add_box_bm(bm_embers, -0.45, 0.45, -0.45, 0.45, 0.02, 0.18, "ember_red")
    add_box_bm(bm_embers, -0.28, 0.28, -0.28, 0.28, 0.05, 0.22, "fire_core")
    bm_embers.normal_update()
    m_embers = bpy.data.meshes.new("CampfireEmbersMesh")
    bm_embers.to_mesh(m_embers)
    bm_embers.free()
    obj_embers = bpy.data.objects.new("Embers", m_embers)
    bpy.context.collection.objects.link(obj_embers)

    # 4. Stylized Faceted Flame Core
    bm_flame = bmesh.new()
    n_f = 6
    v_tip = bm_flame.verts.new((0, 0, 1.25))
    v_ring1 = [bm_flame.verts.new((0.28 * math.cos(i * 2 * math.pi / n_f), 0.28 * math.sin(i * 2 * math.pi / n_f), 0.50)) for i in range(n_f)]
    v_ring0 = [bm_flame.verts.new((0.36 * math.cos(i * 2 * math.pi / n_f + 0.3), 0.36 * math.sin(i * 2 * math.pi / n_f + 0.3), 0.20)) for i in range(n_f)]
    f_flame_top, f_flame_mid = [], []
    for i in range(n_f):
        i_next = (i + 1) % n_f
        f_flame_top.append(bm_flame.faces.new((v_tip, v_ring1[i], v_ring1[i_next])))
        f_flame_mid.append(bm_flame.faces.new((v_ring1[i], v_ring0[i], v_ring0[i_next], v_ring1[i_next])))
    f_flame_bot = bm_flame.faces.new(list(reversed(v_ring0)))
    set_bmesh_uv(bm_flame, f_flame_top, "flame_light")
    set_bmesh_uv(bm_flame, f_flame_mid, "flame_orange")
    set_bmesh_uv(bm_flame, [f_flame_bot], "fire_core")
    bm_flame.normal_update()
    m_flame = bpy.data.meshes.new("CampfireFlameMesh")
    bm_flame.to_mesh(m_flame)
    bm_flame.free()
    obj_flame = bpy.data.objects.new("Flame", m_flame)
    bpy.context.collection.objects.link(obj_flame)

    # Export Package
    root = bpy.data.objects.new("Campfire", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    parts = [obj_stones, obj_logs, obj_embers, obj_flame]
    export_modular_model(root, parts, "campfire", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_ice_crystal():
    """Creates stylized faceted glacier crystal cluster."""
    clear_scene()
    setup_roblox_scene()
    
    def add_crystal_spire(bm, cx, cy, z0, z_tip, r_base, n_sides, tilt_x=0.0, tilt_y=0.0, body_col="ice_glacier", tip_col="ice_light"):
        v_tip = bm.verts.new((cx + tilt_x, cy + tilt_y, z_tip))
        z_mid = z0 + (z_tip - z0) * 0.75
        v_mid = [bm.verts.new((cx + tilt_x*0.6 + (r_base*0.85)*math.cos(i * 2 * math.pi / n_sides), cy + tilt_y*0.6 + (r_base*0.85)*math.sin(i * 2 * math.pi / n_sides), z_mid)) for i in range(n_sides)]
        v_base = [bm.verts.new((cx + r_base*math.cos(i * 2 * math.pi / n_sides + 0.2), cy + r_base*math.sin(i * 2 * math.pi / n_sides + 0.2), z0)) for i in range(n_sides)]
        faces_top, faces_body = [], []
        for i in range(n_sides):
            i_next = (i + 1) % n_sides
            faces_top.append(bm.faces.new((v_tip, v_mid[i], v_mid[i_next])))
            faces_body.append(bm.faces.new((v_mid[i], v_base[i], v_base[i_next], v_mid[i_next])))
        f_bot = bm.faces.new(list(reversed(v_base)))
        set_bmesh_uv(bm, faces_top, tip_col)
        set_bmesh_uv(bm, faces_body, body_col)
        set_bmesh_uv(bm, [f_bot], body_col)

    bm_main = bmesh.new()
    add_crystal_spire(bm_main, 0.0, 0.0, 0.05, 2.2, 0.55, 6, tilt_x=0.15, tilt_y=-0.12, body_col="ice_glacier", tip_col="ice_light")
    bm_main.normal_update()
    m_main = bpy.data.meshes.new("MainSpireMesh")
    bm_main.to_mesh(m_main)
    bm_main.free()
    obj_main = bpy.data.objects.new("MainSpire", m_main)
    bpy.context.collection.objects.link(obj_main)

    bm_left = bmesh.new()
    add_crystal_spire(bm_left, -0.65, 0.20, 0.02, 1.35, 0.38, 5, tilt_x=-0.25, tilt_y=0.15, body_col="ice_deep", tip_col="ice_glacier")
    bm_left.normal_update()
    m_left = bpy.data.meshes.new("ShardLeftMesh")
    bm_left.to_mesh(m_left)
    bm_left.free()
    obj_left = bpy.data.objects.new("ShardLeft", m_left)
    bpy.context.collection.objects.link(obj_left)

    bm_right = bmesh.new()
    add_crystal_spire(bm_right, 0.55, -0.35, 0.02, 1.15, 0.32, 5, tilt_x=0.20, tilt_y=-0.20, body_col="aqua_bright", tip_col="ice_light")
    bm_right.normal_update()
    m_right = bpy.data.meshes.new("ShardRightMesh")
    bm_right.to_mesh(m_right)
    bm_right.free()
    obj_right = bpy.data.objects.new("ShardRight", m_right)
    bpy.context.collection.objects.link(obj_right)

    bm_frost = bmesh.new()
    n_frost = 8
    v_frost = [bm_frost.verts.new(((1.15 + 0.25 * math.sin(i * 3.1)) * math.cos(i * 2 * math.pi / n_frost), (1.15 + 0.25 * math.sin(i * 3.1)) * math.sin(i * 2 * math.pi / n_frost), 0.08)) for i in range(n_frost)]
    v_frost_bot = [bm_frost.verts.new(((1.25 + 0.25 * math.sin(i * 3.1)) * math.cos(i * 2 * math.pi / n_frost), (1.25 + 0.25 * math.sin(i * 3.1)) * math.sin(i * 2 * math.pi / n_frost), 0.0)) for i in range(n_frost)]
    f_frost_side = [bm_frost.faces.new((v_frost[i], v_frost_bot[i], v_frost_bot[(i+1)%n_frost], v_frost[(i+1)%n_frost])) for i in range(n_frost)]
    f_frost_top = bm_frost.faces.new(v_frost)
    f_frost_bot = bm_frost.faces.new(list(reversed(v_frost_bot)))
    set_bmesh_uv(bm_frost, [f_frost_top, f_frost_bot] + f_frost_side, "snow_pure")
    bm_frost.normal_update()
    m_frost = bpy.data.meshes.new("BaseFrostMesh")
    bm_frost.to_mesh(m_frost)
    bm_frost.free()
    obj_frost = bpy.data.objects.new("BaseFrost", m_frost)
    bpy.context.collection.objects.link(obj_frost)

    root = bpy.data.objects.new("IceCrystal", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    parts = [obj_main, obj_left, obj_right, obj_frost]
    export_modular_model(root, parts, "ice_crystal", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources"),
        os.path.join(MODELS_DIR, "nature")
    ])

def create_rabbit_trap():
    """Creates stylized wooden rabbit box trap with stick and carrot bait."""
    clear_scene()
    setup_roblox_scene()
    tilt_rad = math.radians(22)
    cos_t, sin_t = math.cos(tilt_rad), math.sin(tilt_rad)
    by0, by1, bz0, bz1 = -0.65, 0.65, 0.0, 0.75
    bx0, bx1 = -0.75, 0.75

    def add_transformed_box(bm, lx0, lx1, ly0, ly1, lz0, lz1, col):
        verts_local = [
            (lx0, ly0, lz0), (lx1, ly0, lz0), (lx1, ly1, lz0), (lx0, ly1, lz0),
            (lx0, ly0, lz1), (lx1, ly0, lz1), (lx1, ly1, lz1), (lx0, ly1, lz1),
        ]
        v_world = [bm.verts.new((x, (y-by1)*cos_t - z*sin_t + by1, (y-by1)*sin_t + z*cos_t + 0.04)) for (x, y, z) in verts_local]
        f = [
            bm.faces.new((v_world[0], v_world[1], v_world[2], v_world[3])),
            bm.faces.new((v_world[4], v_world[7], v_world[6], v_world[5])),
            bm.faces.new((v_world[0], v_world[4], v_world[5], v_world[1])),
            bm.faces.new((v_world[2], v_world[6], v_world[7], v_world[3])),
            bm.faces.new((v_world[3], v_world[7], v_world[4], v_world[0])),
            bm.faces.new((v_world[1], v_world[5], v_world[6], v_world[2])),
        ]
        if col in COLOR_UV_MAP:
            u, v_coord = COLOR_UV_MAP[col]["u"], COLOR_UV_MAP[col]["v"]
            uv_layer = bm.loops.layers.uv.verify()
            for face in f:
                for loop in face.loops: loop[uv_layer].uv = (u, v_coord)
        return f

    bm_crate = bmesh.new()
    add_transformed_box(bm_crate, bx0, bx1, by0, by1, bz1 - 0.08, bz1, "wood_honey_oak")
    add_transformed_box(bm_crate, bx0, bx0 + 0.07, by0, by1, bz0, bz1 - 0.08, "wood_cedar")
    add_transformed_box(bm_crate, bx1 - 0.07, bx1, by0, by1, bz0, bz1 - 0.08, "wood_cedar")
    add_transformed_box(bm_crate, bx0 + 0.07, bx1 - 0.07, by1 - 0.07, by1, bz0, bz1 - 0.08, "wood_honey_oak")
    add_transformed_box(bm_crate, bx0 + 0.07, bx1 - 0.07, by0, by0 + 0.07, bz0, bz1 - 0.08, "wood_honey_oak")
    bm_crate.normal_update()
    m_crate = bpy.data.meshes.new("CrateMesh")
    bm_crate.to_mesh(m_crate)
    bm_crate.free()
    obj_crate = bpy.data.objects.new("Crate", m_crate)
    bpy.context.collection.objects.link(obj_crate)

    bm_stick = bmesh.new()
    front_lip_y = (by0 - by1) * cos_t + by1
    front_lip_z = (by0 - by1) * sin_t + 0.04
    add_box_bm(bm_stick, -0.04, 0.04, front_lip_y - 0.04, front_lip_y + 0.04, 0.0, front_lip_z + 0.05, "wood_birch")
    bm_stick.normal_update()
    m_stick = bpy.data.meshes.new("PropStickMesh")
    bm_stick.to_mesh(m_stick)
    bm_stick.free()
    obj_stick = bpy.data.objects.new("PropStick", m_stick)
    bpy.context.collection.objects.link(obj_stick)

    bm_carrot = bmesh.new()
    n_c = 6
    v_c_tip = bm_carrot.verts.new((0.28, 0.0, 0.05))
    v_c_fat = [bm_carrot.verts.new((-0.18, 0.09 * math.cos(i * 2 * math.pi / n_c), 0.08 + 0.09 * math.sin(i * 2 * math.pi / n_c))) for i in range(n_c)]
    f_carrot = [bm_carrot.faces.new((v_c_tip, v_c_fat[i], v_c_fat[(i+1)%n_c])) for i in range(n_c)]
    f_carrot_back = bm_carrot.faces.new(list(reversed(v_c_fat)))
    set_bmesh_uv(bm_carrot, f_carrot + [f_carrot_back], "flame_orange")
    bm_carrot.normal_update()
    m_carrot = bpy.data.meshes.new("CarrotMesh")
    bm_carrot.to_mesh(m_carrot)
    bm_carrot.free()
    obj_carrot = bpy.data.objects.new("Carrot", m_carrot)
    bpy.context.collection.objects.link(obj_carrot)

    bm_greens = bmesh.new()
    add_box_bm(bm_greens, -0.32, -0.18, -0.08, 0.08, 0.05, 0.16, "leaf_green")
    add_box_bm(bm_greens, -0.36, -0.22, -0.04, 0.04, 0.12, 0.22, "grass_fresh")
    bm_greens.normal_update()
    m_greens = bpy.data.meshes.new("CarrotGreensMesh")
    bm_greens.to_mesh(m_greens)
    bm_greens.free()
    obj_greens = bpy.data.objects.new("CarrotGreens", m_greens)
    bpy.context.collection.objects.link(obj_greens)

    root = bpy.data.objects.new("RabbitTrap", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    parts = [obj_crate, obj_stick, obj_carrot, obj_greens]
    export_modular_model(root, parts, "rabbit_trap", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_spike_trap():
    """Creates defense spike trap with timber base frame and iron-tipped sharpened stakes."""
    clear_scene()
    setup_roblox_scene()
    fw, tt, th = 1.15, 0.16, 0.14
    
    bm_frame = bmesh.new()
    add_box_bm(bm_frame, -fw, fw, -fw, -fw + tt, 0.0, th, "wood_cedar")
    add_box_bm(bm_frame, -fw, fw, fw - tt, fw, 0.0, th, "wood_cedar")
    add_box_bm(bm_frame, -fw, -fw + tt, -fw + tt, fw - tt, 0.0, th, "wood_cedar")
    add_box_bm(bm_frame, fw - tt, fw, -fw + tt, fw - tt, 0.0, th, "wood_cedar")
    add_box_bm(bm_frame, -fw + tt, fw - tt, -tt/2, tt/2, 0.0, th*0.8, "wood_honey_oak")
    c_sz = 0.22
    for cx in [-fw, fw - c_sz]:
        for cy in [-fw, fw - c_sz]:
            add_box_bm(bm_frame, cx, cx + c_sz, cy, cy + c_sz, 0.0, th + 0.02, "iron_band")
    bm_frame.normal_update()
    m_frame = bpy.data.meshes.new("BaseFrameMesh")
    bm_frame.to_mesh(m_frame)
    bm_frame.free()
    obj_frame = bpy.data.objects.new("BaseFrame", m_frame)
    bpy.context.collection.objects.link(obj_frame)

    bm_spikes = bmesh.new()
    spike_configs = [
        ( 0.0,  0.0, 0.05,  0.0,  0.0, 1.45, 0.12, "wood_honey_oak", "slate_light"),
        (-0.50, -0.50, 0.05, -0.82, -0.82, 1.15, 0.10, "wood_cedar", "iron_band"),
        ( 0.50, -0.50, 0.05,  0.82, -0.82, 1.15, 0.10, "wood_cedar", "iron_band"),
        (-0.50,  0.50, 0.05, -0.82,  0.82, 1.15, 0.10, "wood_cedar", "iron_band"),
        ( 0.50,  0.50, 0.05,  0.82,  0.82, 1.15, 0.10, "wood_cedar", "iron_band"),
    ]
    for (xb, yb, zb, xt, yt, zt, r, col_b, col_t) in spike_configs:
        n_sp = 5
        dx, dy, dz = xt - xb, yt - yb, zt - zb
        v_t = bm_spikes.verts.new((xt, yt, zt))
        t_mid = 0.65
        xm, ym, zm = xb + dx*t_mid, yb + dy*t_mid, zb + dz*t_mid
        v_mid = [bm_spikes.verts.new((xm + (r*0.6)*math.cos(i * 2 * math.pi / n_sp), ym + (r*0.6)*math.sin(i * 2 * math.pi / n_sp), zm)) for i in range(n_sp)]
        v_base = [bm_spikes.verts.new((xb + r*math.cos(i * 2 * math.pi / n_sp), yb + r*math.sin(i * 2 * math.pi / n_sp), zb)) for i in range(n_sp)]
        f_top, f_body = [], []
        for i in range(n_sp):
            i_next = (i + 1) % n_sp
            f_top.append(bm_spikes.faces.new((v_t, v_mid[i], v_mid[i_next])))
            f_body.append(bm_spikes.faces.new((v_mid[i], v_base[i], v_base[i_next], v_mid[i_next])))
        f_bot = bm_spikes.faces.new(list(reversed(v_base)))
        set_bmesh_uv(bm_spikes, f_top, col_t)
        set_bmesh_uv(bm_spikes, f_body, col_b)
        set_bmesh_uv(bm_spikes, [f_bot], col_b)
    bm_spikes.normal_update()
    m_spikes = bpy.data.meshes.new("SpikesMesh")
    bm_spikes.to_mesh(m_spikes)
    bm_spikes.free()
    obj_spikes = bpy.data.objects.new("Spikes", m_spikes)
    bpy.context.collection.objects.link(obj_spikes)

    root = bpy.data.objects.new("SpikeTrap", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    parts = [obj_frame, obj_spikes]
    export_modular_model(root, parts, "spike_trap", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "interactive"),
        os.path.join(MODELS_DIR, "resources")
    ])

# ==============================================================================
# 2.3. 🌲 Natural Resources (Nature Spawns)
# ==============================================================================

def create_branches():
    """Creates stylized low-poly fallen branches with pine needle foliage clusters."""
    clear_scene()
    setup_roblox_scene()

    bm_sticks = bmesh.new()
    def add_tapered_stick(bm, start, end, r_base, r_tip, n_sides, col):
        sx, sy, sz = start
        ex, ey, ez = end
        dx, dy, dz = ex - sx, ey - sy, ez - sz
        length = math.sqrt(dx*dx + dy*dy + dz*dz)
        if length < 1e-4: return
        ux, uy, uz = dx/length, dy/length, dz/length
        if abs(uz) < 0.9:
            px, py, pz = -uy, ux, 0.0
        else:
            px, py, pz = 0.0, -uz, uy
        plen = math.sqrt(px*px + py*py + pz*pz)
        px, py, pz = px/plen, py/plen, pz/plen
        qx = uy*pz - uz*py
        qy = uz*px - ux*pz
        qz = ux*py - uy*px

        v_base = []
        v_tip = []
        for i in range(n_sides):
            ang = 2 * math.pi * i / n_sides
            c, s = math.cos(ang), math.sin(ang)
            bx = sx + r_base * (c*px + s*qx)
            by = sy + r_base * (c*py + s*qy)
            bz = sz + r_base * (c*pz + s*qz)
            v_base.append(bm.verts.new((bx, by, bz)))

            tx = ex + r_tip * (c*px + s*qx)
            ty = ey + r_tip * (c*py + s*qy)
            tz = ez + r_tip * (c*pz + s*qz)
            v_tip.append(bm.verts.new((tx, ty, tz)))

        faces = []
        for i in range(n_sides):
            i_next = (i + 1) % n_sides
            faces.append(bm.faces.new((v_base[i], v_base[i_next], v_tip[i_next], v_tip[i])))
        f_b = bm.faces.new(list(reversed(v_base)))
        f_t = bm.faces.new(v_tip)
        set_bmesh_uv(bm, faces + [f_b, f_t], col)

    # 3 crossed branches
    add_tapered_stick(bm_sticks, (-0.75, -0.22, 0.04), (0.75, 0.28, 0.12), 0.052, 0.032, 6, "wood_cedar")
    add_tapered_stick(bm_sticks, (-0.35, 0.55, 0.04), (0.42, -0.52, 0.10), 0.046, 0.028, 6, "wood_pine")
    add_tapered_stick(bm_sticks, (0.12, 0.08, 0.08), (-0.52, -0.38, 0.15), 0.038, 0.022, 5, "wood_honey_oak")
    bm_sticks.normal_update()
    m_sticks = bpy.data.meshes.new("SticksMesh")
    bm_sticks.to_mesh(m_sticks)
    bm_sticks.free()
    obj_sticks = bpy.data.objects.new("Sticks", m_sticks)
    bpy.context.collection.objects.link(obj_sticks)

    # Needles part
    bm_needles = bmesh.new()
    def add_needle_fan(bm, center, dir_angle, scale, col):
        cx, cy, cz = center
        for a_off, l_mult in [(-0.35, 0.85), (0.0, 1.15), (0.35, 0.90)]:
            ang = dir_angle + a_off
            cos_a, sin_a = math.cos(ang), math.sin(ang)
            l = scale * l_mult
            w = scale * 0.28
            v_root = bm.verts.new((cx, cy, cz))
            v_left = bm.verts.new((cx + cos_a*l*0.45 - sin_a*w, cy + sin_a*l*0.45 + cos_a*w, cz + 0.03))
            v_right = bm.verts.new((cx + cos_a*l*0.45 + sin_a*w, cy + sin_a*l*0.45 - cos_a*w, cz + 0.03))
            v_tip = bm.verts.new((cx + cos_a*l, cy + sin_a*l, cz + 0.05))
            v_bot = bm.verts.new((cx + cos_a*l*0.45, cy + sin_a*l*0.45, cz - 0.02))
            f1 = bm.faces.new((v_root, v_left, v_tip))
            f2 = bm.faces.new((v_root, v_tip, v_right))
            f3 = bm.faces.new((v_root, v_right, v_bot))
            f4 = bm.faces.new((v_root, v_bot, v_left))
            set_bmesh_uv(bm, [f1, f2, f3, f4], col)

    add_needle_fan(bm_needles, (0.75, 0.28, 0.12), 0.35, 0.28, "pine_green")
    add_needle_fan(bm_needles, (-0.75, -0.22, 0.04), math.pi + 0.28, 0.25, "pine_dark")
    add_needle_fan(bm_needles, (-0.35, 0.55, 0.04), 2.1, 0.24, "leaf_green")
    add_needle_fan(bm_needles, (0.42, -0.52, 0.10), -0.85, 0.26, "pine_green")
    bm_needles.normal_update()
    m_needles = bpy.data.meshes.new("NeedlesMesh")
    bm_needles.to_mesh(m_needles)
    bm_needles.free()
    obj_needles = bpy.data.objects.new("Needles", m_needles)
    bpy.context.collection.objects.link(obj_needles)

    root = bpy.data.objects.new("Branches", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_sticks, obj_needles], "branches", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "nature"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_stone():
    """Creates faceted low-poly stone boulder with stylized snow cap."""
    clear_scene()
    setup_roblox_scene()

    bm_rock = bmesh.new()
    n_pts = 7
    v_base = []
    r_base = [0.72, 0.85, 0.68, 0.82, 0.76, 0.88, 0.70]
    for i in range(n_pts):
        ang = 2 * math.pi * i / n_pts
        v_base.append(bm_rock.verts.new((r_base[i] * math.cos(ang), r_base[i] * math.sin(ang) * 0.85, 0.04)))
    
    v_mid = []
    r_mid = [0.82, 0.95, 0.78, 0.92, 0.84, 0.98, 0.80]
    for i in range(n_pts):
        ang = 2 * math.pi * i / n_pts + 0.18
        v_mid.append(bm_rock.verts.new((r_mid[i] * math.cos(ang), r_mid[i] * math.sin(ang) * 0.88, 0.45)))

    v_up = []
    r_up = [0.55, 0.65, 0.50, 0.62, 0.58, 0.68, 0.52]
    for i in range(n_pts):
        ang = 2 * math.pi * i / n_pts + 0.35
        v_up.append(bm_rock.verts.new((r_up[i] * math.cos(ang), r_up[i] * math.sin(ang) * 0.82, 0.78)))

    v_top = bm_rock.verts.new((0.05, -0.04, 0.95))

    f_bottom = bm_rock.faces.new(list(reversed(v_base)))
    f_low, f_mid, f_top = [], [], []
    for i in range(n_pts):
        i_next = (i + 1) % n_pts
        f_low.append(bm_rock.faces.new((v_base[i], v_base[i_next], v_mid[i_next], v_mid[i])))
        f_mid.append(bm_rock.faces.new((v_mid[i], v_mid[i_next], v_up[i_next], v_up[i])))
        f_top.append(bm_rock.faces.new((v_up[i], v_up[i_next], v_top)))

    set_bmesh_uv(bm_rock, [f_bottom] + f_low, "stone_dark")
    set_bmesh_uv(bm_rock, f_mid + f_top, "stone_slate")
    bm_rock.normal_update()
    m_rock = bpy.data.meshes.new("BoulderMesh")
    bm_rock.to_mesh(m_rock)
    bm_rock.free()
    obj_rock = bpy.data.objects.new("Boulder", m_rock)
    bpy.context.collection.objects.link(obj_rock)

    bm_snow = bmesh.new()
    v_snow_crest = bm_snow.verts.new((0.05, -0.04, 1.05))
    v_snow_mid = []
    for i in range(n_pts):
        ang = 2 * math.pi * i / n_pts + 0.35
        v_snow_mid.append(bm_snow.verts.new(((r_up[i]+0.06) * math.cos(ang), (r_up[i]+0.06) * math.sin(ang) * 0.82, 0.84)))
    v_snow_lip = []
    for i in range(n_pts):
        ang = 2 * math.pi * i / n_pts + 0.35
        lip_z = 0.65 if i % 2 == 0 else 0.72
        v_snow_lip.append(bm_snow.verts.new(((r_up[i]+0.08) * math.cos(ang), (r_up[i]+0.08) * math.sin(ang) * 0.82, lip_z)))

    f_s_top, f_s_side = [], []
    for i in range(n_pts):
        i_next = (i + 1) % n_pts
        f_s_top.append(bm_snow.faces.new((v_snow_crest, v_snow_mid[i], v_snow_mid[i_next])))
        f_s_side.append(bm_snow.faces.new((v_snow_mid[i], v_snow_lip[i], v_snow_lip[i_next], v_snow_mid[i_next])))
    f_s_bot = [bm_snow.faces.new(list(reversed(v_snow_lip)))]
    set_bmesh_uv(bm_snow, f_s_top, "snow_pure")
    set_bmesh_uv(bm_snow, f_s_side + f_s_bot, "snow_ambient")
    bm_snow.normal_update()
    m_snow = bpy.data.meshes.new("SnowCapMesh")
    bm_snow.to_mesh(m_snow)
    bm_snow.free()
    obj_snow = bpy.data.objects.new("SnowCap", m_snow)
    bpy.context.collection.objects.link(obj_snow)

    root = bpy.data.objects.new("Stone", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_rock, obj_snow], "stone", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "nature"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_fiber():
    """Creates stylized golden grass fiber stalks and tied bundle base."""
    clear_scene()
    setup_roblox_scene()

    bm_stalks = bmesh.new()
    def add_curved_blade(bm, pts, width, col):
        left_verts, right_verts, center_verts = [], [], []
        n_segs = len(pts)
        for idx, (x, y, z) in enumerate(pts):
            t = idx / (n_segs - 1)
            w = width * (1.0 - t * 0.85)
            if idx < n_segs - 1:
                dx = pts[idx+1][0] - x
                dy = pts[idx+1][1] - y
            else:
                dx = x - pts[idx-1][0]
                dy = y - pts[idx-1][1]
            mag = math.sqrt(dx*dx + dy*dy) or 1.0
            nx, ny = -dy/mag * w, dx/mag * w
            left_verts.append(bm.verts.new((x + nx, y + ny, z)))
            right_verts.append(bm.verts.new((x - nx, y - ny, z)))
            center_verts.append(bm.verts.new((x, y, z + w*0.45)))
        
        faces = []
        for i in range(n_segs - 1):
            faces.append(bm.faces.new((left_verts[i], center_verts[i], center_verts[i+1], left_verts[i+1])))
            faces.append(bm.faces.new((center_verts[i], right_verts[i], right_verts[i+1], center_verts[i+1])))
            faces.append(bm.faces.new((left_verts[i], left_verts[i+1], right_verts[i+1], right_verts[i])))
        set_bmesh_uv(bm, faces, col)

    pts_center = [(0.0, 0.0, 0.05), (0.0, 0.06, 0.35), (0.02, 0.16, 0.72), (0.05, 0.28, 1.05)]
    pts_left = [(-0.08, 0.0, 0.05), (-0.22, 0.08, 0.32), (-0.38, 0.18, 0.62), (-0.52, 0.28, 0.78)]
    pts_right = [(0.08, -0.02, 0.05), (0.24, -0.08, 0.34), (0.42, -0.16, 0.65), (0.58, -0.22, 0.82)]

    add_curved_blade(bm_stalks, pts_center, 0.11, "twine_straw")
    add_curved_blade(bm_stalks, pts_left, 0.09, "fiber_gold")
    add_curved_blade(bm_stalks, pts_right, 0.095, "fiber_gold")
    bm_stalks.normal_update()
    m_stalks = bpy.data.meshes.new("StalksMesh")
    bm_stalks.to_mesh(m_stalks)
    bm_stalks.free()
    obj_stalks = bpy.data.objects.new("Stalks", m_stalks)
    bpy.context.collection.objects.link(obj_stalks)

    bm_base = bmesh.new()
    add_box_bm(bm_base, -0.15, 0.15, -0.12, 0.12, 0.0, 0.14, "leather_tan")
    add_box_bm(bm_base, -0.18, 0.18, -0.15, 0.15, 0.04, 0.10, "leather_warm")
    bm_base.normal_update()
    m_base = bpy.data.meshes.new("BaseMesh")
    bm_base.to_mesh(m_base)
    bm_base.free()
    obj_base = bpy.data.objects.new("Base", m_base)
    bpy.context.collection.objects.link(obj_base)

    root = bpy.data.objects.new("Fiber", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_stalks, obj_base], "fiber", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "nature"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_planks():
    """Creates a neat 2x2 criss-cross stack of 4 lumber planks."""
    clear_scene()
    setup_roblox_scene()

    bm_planks = bmesh.new()
    add_box_bm(bm_planks, -0.80, 0.78, -0.48, -0.14, 0.0, 0.14, "wood_honey_oak")
    add_box_bm(bm_planks, -0.76, 0.82, 0.14, 0.48, 0.0, 0.14, "wood_cedar")
    add_box_bm(bm_planks, -0.48, -0.14, -0.78, 0.80, 0.14, 0.28, "wood_pine")
    add_box_bm(bm_planks, 0.14, 0.48, -0.82, 0.76, 0.14, 0.28, "wood_honey_oak")

    bm_planks.normal_update()
    m_planks = bpy.data.meshes.new("PlanksMesh")
    bm_planks.to_mesh(m_planks)
    bm_planks.free()
    obj_planks = bpy.data.objects.new("Planks", m_planks)
    bpy.context.collection.objects.link(obj_planks)

    root = bpy.data.objects.new("Planks", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_planks], "planks", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "nature"),
        os.path.join(MODELS_DIR, "resources")
    ])

def create_fir_tree():
    """Creates stylized low-poly cartoon cone-tiered fir tree with snow blankets."""
    clear_scene()
    setup_roblox_scene()

    bm_trunk = bmesh.new()
    n_t = 6
    v_t_base = [bm_trunk.verts.new((0.26 * math.cos(i*2*math.pi/n_t), 0.26 * math.sin(i*2*math.pi/n_t), 0.0)) for i in range(n_t)]
    v_t_top = [bm_trunk.verts.new((0.15 * math.cos(i*2*math.pi/n_t), 0.15 * math.sin(i*2*math.pi/n_t), 1.6)) for i in range(n_t)]
    f_t_side = [bm_trunk.faces.new((v_t_base[i], v_t_base[(i+1)%n_t], v_t_top[(i+1)%n_t], v_t_top[i])) for i in range(n_t)]
    f_t_bot = bm_trunk.faces.new(list(reversed(v_t_base)))
    set_bmesh_uv(bm_trunk, f_t_side + [f_t_bot], "wood_bark")
    bm_trunk.normal_update()
    m_trunk = bpy.data.meshes.new("TrunkMesh")
    bm_trunk.to_mesh(m_trunk)
    bm_trunk.free()
    obj_trunk = bpy.data.objects.new("Trunk", m_trunk)
    bpy.context.collection.objects.link(obj_trunk)

    bm_foliage = bmesh.new()
    def add_tree_tier(bm, z_bot, z_top, r_bot, r_top, n_sides, col):
        v_b = [bm.verts.new((r_bot * math.cos(i*2*math.pi/n_sides), r_bot * math.sin(i*2*math.pi/n_sides), z_bot)) for i in range(n_sides)]
        if r_top > 0.01:
            v_t = [bm.verts.new((r_top * math.cos(i*2*math.pi/n_sides), r_top * math.sin(i*2*math.pi/n_sides), z_top)) for i in range(n_sides)]
            f_side = [bm.faces.new((v_b[i], v_b[(i+1)%n_sides], v_t[(i+1)%n_sides], v_t[i])) for i in range(n_sides)]
        else:
            v_peak = bm.verts.new((0.0, 0.0, z_top))
            f_side = [bm.faces.new((v_b[i], v_b[(i+1)%n_sides], v_peak)) for i in range(n_sides)]
        f_bot = bm.faces.new(list(reversed(v_b)))
        set_bmesh_uv(bm, f_side + [f_bot], col)

    add_tree_tier(bm_foliage, 0.75, 2.10, 1.45, 0.85, 8, "pine_dark")
    add_tree_tier(bm_foliage, 1.80, 3.15, 1.10, 0.55, 8, "pine_green")
    add_tree_tier(bm_foliage, 2.75, 4.25, 0.72, 0.00, 8, "pine_green")
    bm_foliage.normal_update()
    m_foliage = bpy.data.meshes.new("FoliageMesh")
    bm_foliage.to_mesh(m_foliage)
    bm_foliage.free()
    obj_foliage = bpy.data.objects.new("Foliage", m_foliage)
    bpy.context.collection.objects.link(obj_foliage)

    bm_snow = bmesh.new()
    def add_snow_tier(bm, z_center, r_center, n_sides):
        for i in range(n_sides):
            ang = i * 2 * math.pi / n_sides
            ang_next = (i + 1) * 2 * math.pi / n_sides
            cx1, cy1 = r_center * math.cos(ang), r_center * math.sin(ang)
            cx2, cy2 = r_center * math.cos(ang_next), r_center * math.sin(ang_next)
            v1 = bm.verts.new((cx1, cy1, z_center + 0.06))
            v2 = bm.verts.new((cx2, cy2, z_center + 0.06))
            v3 = bm.verts.new(((r_center+0.12) * math.cos((ang+ang_next)/2), (r_center+0.12) * math.sin((ang+ang_next)/2), z_center - 0.12))
            v4 = bm.verts.new((cx1*0.7, cy1*0.7, z_center + 0.35))
            v5 = bm.verts.new((cx2*0.7, cy2*0.7, z_center + 0.35))
            f1 = bm.faces.new((v4, v5, v2, v1))
            f2 = bm.faces.new((v1, v2, v3))
            set_bmesh_uv(bm, [f1, f2], "snow_pure")

    add_snow_tier(bm_snow, 0.80, 1.48, 8)
    add_snow_tier(bm_snow, 1.85, 1.12, 8)
    add_snow_tier(bm_snow, 2.80, 0.74, 8)
    bm_snow.normal_update()
    m_snow = bpy.data.meshes.new("SnowTrimMesh")
    bm_snow.to_mesh(m_snow)
    bm_snow.free()
    obj_snow = bpy.data.objects.new("SnowTrim", m_snow)
    bpy.context.collection.objects.link(obj_snow)

    root = bpy.data.objects.new("FirTree", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_trunk, obj_foliage, obj_snow], "fir_tree", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "nature"),
        os.path.join(MODELS_DIR, "resources")
    ])

# ==============================================================================
# 2.4. 🐺 Enemies & Monsters (FBX/OBJ)
# ==============================================================================

def create_wolf():
    """Creates stylized low-poly forest wolf with glowing red eyes."""
    clear_scene()
    setup_roblox_scene()

    bm_body = bmesh.new()
    add_box_bm(bm_body, -0.34, 0.34, -0.10, 0.65, 0.55, 1.25, "stone_dark")
    add_box_bm(bm_body, -0.26, 0.26, 0.15, 0.68, 0.48, 0.85, "slate_light")
    add_box_bm(bm_body, -0.28, 0.28, -0.72, -0.10, 0.58, 1.15, "stone_dark")
    bm_body.normal_update()
    m_body = bpy.data.meshes.new("WolfBodyMesh")
    bm_body.to_mesh(m_body)
    bm_body.free()
    obj_body = bpy.data.objects.new("Body", m_body)
    bpy.context.collection.objects.link(obj_body)

    bm_head = bmesh.new()
    add_box_bm(bm_head, -0.25, 0.25, 0.58, 1.05, 0.85, 1.38, "stone_dark")
    add_box_bm(bm_head, -0.34, -0.25, 0.62, 0.95, 0.82, 1.15, "slate_light")
    add_box_bm(bm_head, 0.25, 0.34, 0.62, 0.95, 0.82, 1.15, "slate_light")
    add_box_bm(bm_head, -0.15, 0.15, 1.05, 1.52, 0.82, 1.08, "stone_dark")
    add_box_bm(bm_head, -0.06, 0.06, 1.50, 1.58, 0.98, 1.08, "pitch_black")
    add_box_bm(bm_head, -0.12, 0.12, 1.02, 1.45, 0.70, 0.82, "slate_light")
    bm_head.normal_update()
    m_head = bpy.data.meshes.new("WolfHeadMesh")
    bm_head.to_mesh(m_head)
    bm_head.free()
    obj_head = bpy.data.objects.new("Head", m_head)
    bpy.context.collection.objects.link(obj_head)

    bm_ears = bmesh.new()
    v_el = [
        bm_ears.verts.new((-0.24, 0.70, 1.38)), bm_ears.verts.new((-0.08, 0.70, 1.38)),
        bm_ears.verts.new((-0.08, 0.92, 1.38)), bm_ears.verts.new((-0.24, 0.92, 1.38)),
        bm_ears.verts.new((-0.16, 0.78, 1.72))
    ]
    f_el = [
        bm_ears.faces.new((v_el[0], v_el[1], v_el[4])),
        bm_ears.faces.new((v_el[1], v_el[2], v_el[4])),
        bm_ears.faces.new((v_el[2], v_el[3], v_el[4])),
        bm_ears.faces.new((v_el[3], v_el[0], v_el[4])),
    ]
    set_bmesh_uv(bm_ears, [f_el[0]], "pink_soft")
    set_bmesh_uv(bm_ears, f_el[1:], "stone_dark")

    v_er = [
        bm_ears.verts.new((0.08, 0.70, 1.38)), bm_ears.verts.new((0.24, 0.70, 1.38)),
        bm_ears.verts.new((0.24, 0.92, 1.38)), bm_ears.verts.new((0.08, 0.92, 1.38)),
        bm_ears.verts.new((0.16, 0.78, 1.72))
    ]
    f_er = [
        bm_ears.faces.new((v_er[0], v_er[1], v_er[4])),
        bm_ears.faces.new((v_er[1], v_er[2], v_er[4])),
        bm_ears.faces.new((v_er[2], v_er[3], v_er[4])),
        bm_ears.faces.new((v_er[3], v_er[0], v_er[4])),
    ]
    set_bmesh_uv(bm_ears, [f_er[0]], "pink_soft")
    set_bmesh_uv(bm_ears, f_er[1:], "stone_dark")

    bm_ears.normal_update()
    m_ears = bpy.data.meshes.new("WolfEarsMesh")
    bm_ears.to_mesh(m_ears)
    bm_ears.free()
    obj_ears = bpy.data.objects.new("Ears", m_ears)
    bpy.context.collection.objects.link(obj_ears)

    bm_legs = bmesh.new()
    add_box_bm(bm_legs, -0.32, -0.16, 0.35, 0.55, 0.0, 0.65, "stone_dark")
    add_box_bm(bm_legs, -0.34, -0.14, 0.42, 0.62, 0.0, 0.12, "cast_iron")
    add_box_bm(bm_legs, 0.16, 0.32, 0.35, 0.55, 0.0, 0.65, "stone_dark")
    add_box_bm(bm_legs, 0.14, 0.34, 0.42, 0.62, 0.0, 0.12, "cast_iron")
    add_box_bm(bm_legs, -0.30, -0.14, -0.68, -0.45, 0.0, 0.68, "stone_dark")
    add_box_bm(bm_legs, -0.32, -0.12, -0.62, -0.38, 0.0, 0.12, "cast_iron")
    add_box_bm(bm_legs, 0.14, 0.30, -0.68, -0.45, 0.0, 0.68, "stone_dark")
    add_box_bm(bm_legs, 0.12, 0.32, -0.62, -0.38, 0.0, 0.12, "cast_iron")
    bm_legs.normal_update()
    m_legs = bpy.data.meshes.new("WolfLegsMesh")
    bm_legs.to_mesh(m_legs)
    bm_legs.free()
    obj_legs = bpy.data.objects.new("Legs", m_legs)
    bpy.context.collection.objects.link(obj_legs)

    bm_tail = bmesh.new()
    add_box_bm(bm_tail, -0.12, 0.12, -1.05, -0.68, 0.75, 1.05, "stone_dark")
    add_box_bm(bm_tail, -0.10, 0.10, -1.35, -1.05, 0.85, 1.15, "slate_light")
    bm_tail.normal_update()
    m_tail = bpy.data.meshes.new("WolfTailMesh")
    bm_tail.to_mesh(m_tail)
    bm_tail.free()
    obj_tail = bpy.data.objects.new("Tail", m_tail)
    bpy.context.collection.objects.link(obj_tail)

    bm_eyes = bmesh.new()
    add_box_bm(bm_eyes, -0.22, -0.12, 0.96, 1.08, 1.12, 1.22, "neon_red_glow")
    add_box_bm(bm_eyes, 0.12, 0.22, 0.96, 1.08, 1.12, 1.22, "neon_red_glow")
    bm_eyes.normal_update()
    m_eyes = bpy.data.meshes.new("WolfEyesMesh")
    bm_eyes.to_mesh(m_eyes)
    bm_eyes.free()
    obj_eyes = bpy.data.objects.new("Eyes", m_eyes)
    bpy.context.collection.objects.link(obj_eyes)

    root = bpy.data.objects.new("Wolf", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_body, obj_head, obj_ears, obj_legs, obj_tail, obj_eyes], "wolf", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "monsters"),
        os.path.join(MODELS_DIR, "mobs")
    ])

def create_yeti():
    """Creates stylized low-poly snowy Yeti with curved ice horns and glowing cyan eyes."""
    clear_scene()
    setup_roblox_scene()

    bm_torso = bmesh.new()
    add_box_bm(bm_torso, -0.72, 0.72, -0.58, 0.58, 0.72, 1.95, "snow_pure")
    add_box_bm(bm_torso, -0.62, 0.62, -0.48, 0.68, 0.85, 1.85, "snow_ambient")
    add_box_bm(bm_torso, -0.85, 0.85, -0.55, 0.55, 1.65, 2.15, "snow_pure")
    bm_torso.normal_update()
    m_torso = bpy.data.meshes.new("YetiTorsoMesh")
    bm_torso.to_mesh(m_torso)
    bm_torso.free()
    obj_torso = bpy.data.objects.new("Torso", m_torso)
    bpy.context.collection.objects.link(obj_torso)

    bm_head = bmesh.new()
    add_box_bm(bm_head, -0.42, 0.42, -0.32, 0.42, 1.95, 2.65, "snow_pure")
    add_box_bm(bm_head, -0.32, 0.32, 0.28, 0.48, 2.05, 2.52, "stone_dark")
    add_box_bm(bm_head, -0.22, -0.14, 0.46, 0.52, 2.05, 2.22, "snow_pure")
    add_box_bm(bm_head, 0.14, 0.22, 0.46, 0.52, 2.05, 2.22, "snow_pure")
    bm_head.normal_update()
    m_head = bpy.data.meshes.new("YetiHeadMesh")
    bm_head.to_mesh(m_head)
    bm_head.free()
    obj_head = bpy.data.objects.new("Head", m_head)
    bpy.context.collection.objects.link(obj_head)

    bm_horns = bmesh.new()
    add_box_bm(bm_horns, -0.52, -0.35, -0.05, 0.15, 2.55, 2.82, "ice_glacier")
    add_box_bm(bm_horns, -0.68, -0.48, -0.22, 0.02, 2.75, 3.05, "ice_light")
    add_box_bm(bm_horns, 0.35, 0.52, -0.05, 0.15, 2.55, 2.82, "ice_glacier")
    add_box_bm(bm_horns, 0.48, 0.68, -0.22, 0.02, 2.75, 3.05, "ice_light")
    bm_horns.normal_update()
    m_horns = bpy.data.meshes.new("YetiHornsMesh")
    bm_horns.to_mesh(m_horns)
    bm_horns.free()
    obj_horns = bpy.data.objects.new("Horns", m_horns)
    bpy.context.collection.objects.link(obj_horns)

    bm_arms = bmesh.new()
    add_box_bm(bm_arms, -1.05, -0.72, -0.25, 0.25, 0.95, 2.05, "snow_pure")
    add_box_bm(bm_arms, -1.15, -0.78, 0.05, 0.35, 0.35, 1.05, "snow_ambient")
    add_box_bm(bm_arms, -1.18, -0.75, 0.12, 0.42, 0.25, 0.55, "ice_deep")
    add_box_bm(bm_arms, 0.72, 1.05, -0.25, 0.25, 0.95, 2.05, "snow_pure")
    add_box_bm(bm_arms, 0.78, 1.15, 0.05, 0.35, 0.35, 1.05, "snow_ambient")
    add_box_bm(bm_arms, 0.75, 1.18, 0.12, 0.42, 0.25, 0.55, "ice_deep")
    bm_arms.normal_update()
    m_arms = bpy.data.meshes.new("YetiArmsMesh")
    bm_arms.to_mesh(m_arms)
    bm_arms.free()
    obj_arms = bpy.data.objects.new("Arms", m_arms)
    bpy.context.collection.objects.link(obj_arms)

    bm_legs = bmesh.new()
    add_box_bm(bm_legs, -0.62, -0.22, -0.32, 0.32, 0.0, 0.85, "snow_ambient")
    add_box_bm(bm_legs, -0.66, -0.18, -0.25, 0.45, 0.0, 0.22, "ice_light")
    add_box_bm(bm_legs, 0.22, 0.62, -0.32, 0.32, 0.0, 0.85, "snow_ambient")
    add_box_bm(bm_legs, 0.18, 0.66, -0.25, 0.45, 0.0, 0.22, "ice_light")
    bm_legs.normal_update()
    m_legs = bpy.data.meshes.new("YetiLegsMesh")
    bm_legs.to_mesh(m_legs)
    bm_legs.free()
    obj_legs = bpy.data.objects.new("Legs", m_legs)
    bpy.context.collection.objects.link(obj_legs)

    bm_eyes = bmesh.new()
    add_box_bm(bm_eyes, -0.22, -0.08, 0.44, 0.52, 2.30, 2.44, "neon_cyan_glow")
    add_box_bm(bm_eyes, 0.08, 0.22, 0.44, 0.52, 2.30, 2.44, "neon_cyan_glow")
    bm_eyes.normal_update()
    m_eyes = bpy.data.meshes.new("YetiEyesMesh")
    bm_eyes.to_mesh(m_eyes)
    bm_eyes.free()
    obj_eyes = bpy.data.objects.new("Eyes", m_eyes)
    bpy.context.collection.objects.link(obj_eyes)

    root = bpy.data.objects.new("Yeti", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_torso, obj_head, obj_horns, obj_arms, obj_legs, obj_eyes], "yeti", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "monsters"),
        os.path.join(MODELS_DIR, "mobs")
    ])

def create_bigfoot():
    """Creates stylized low-poly giant Bigfoot with glowing amber eyes."""
    clear_scene()
    setup_roblox_scene()

    bm_torso = bmesh.new()
    add_box_bm(bm_torso, -0.80, 0.80, -0.52, 0.52, 0.85, 2.15, "wood_walnut")
    add_box_bm(bm_torso, -0.72, 0.72, 0.35, 0.62, 1.25, 1.95, "wood_bark")
    add_box_bm(bm_torso, -0.65, 0.65, -0.62, -0.35, 1.05, 2.10, "soil_rich")
    bm_torso.normal_update()
    m_torso = bpy.data.meshes.new("BigfootTorsoMesh")
    bm_torso.to_mesh(m_torso)
    bm_torso.free()
    obj_torso = bpy.data.objects.new("Torso", m_torso)
    bpy.context.collection.objects.link(obj_torso)

    bm_head = bmesh.new()
    add_box_bm(bm_head, -0.40, 0.40, -0.28, 0.38, 2.05, 2.75, "wood_walnut")
    add_box_bm(bm_head, -0.38, 0.38, 0.28, 0.48, 2.38, 2.62, "wood_burnt")
    add_box_bm(bm_head, -0.28, 0.28, 0.32, 0.52, 2.05, 2.35, "soil_dark")
    bm_head.normal_update()
    m_head = bpy.data.meshes.new("BigfootHeadMesh")
    bm_head.to_mesh(m_head)
    bm_head.free()
    obj_head = bpy.data.objects.new("Head", m_head)
    bpy.context.collection.objects.link(obj_head)

    bm_arms = bmesh.new()
    add_box_bm(bm_arms, -1.15, -0.80, -0.28, 0.28, 1.05, 2.15, "wood_bark")
    add_box_bm(bm_arms, -1.22, -0.85, 0.05, 0.38, 0.35, 1.15, "wood_walnut")
    add_box_bm(bm_arms, -1.25, -0.82, 0.12, 0.45, 0.20, 0.52, "wood_burnt")
    add_box_bm(bm_arms, 0.80, 1.15, -0.28, 0.28, 1.05, 2.15, "wood_bark")
    add_box_bm(bm_arms, 0.85, 1.22, 0.05, 0.38, 0.35, 1.15, "wood_walnut")
    add_box_bm(bm_arms, 0.82, 1.25, 0.12, 0.45, 0.20, 0.52, "wood_burnt")
    bm_arms.normal_update()
    m_arms = bpy.data.meshes.new("BigfootArmsMesh")
    bm_arms.to_mesh(m_arms)
    bm_arms.free()
    obj_arms = bpy.data.objects.new("Arms", m_arms)
    bpy.context.collection.objects.link(obj_arms)

    bm_legs = bmesh.new()
    add_box_bm(bm_legs, -0.68, -0.24, -0.35, 0.35, 0.0, 0.95, "wood_walnut")
    add_box_bm(bm_legs, -0.74, -0.18, -0.25, 0.55, 0.0, 0.25, "wood_burnt")
    add_box_bm(bm_legs, 0.24, 0.68, -0.35, 0.35, 0.0, 0.95, "wood_walnut")
    add_box_bm(bm_legs, 0.18, 0.74, -0.25, 0.55, 0.0, 0.25, "wood_burnt")
    bm_legs.normal_update()
    m_legs = bpy.data.meshes.new("BigfootLegsMesh")
    bm_legs.to_mesh(m_legs)
    bm_legs.free()
    obj_legs = bpy.data.objects.new("Legs", m_legs)
    bpy.context.collection.objects.link(obj_legs)

    bm_eyes = bmesh.new()
    add_box_bm(bm_eyes, -0.22, -0.08, 0.42, 0.50, 2.40, 2.52, "neon_amber_glow")
    add_box_bm(bm_eyes, 0.08, 0.22, 0.42, 0.50, 2.40, 2.52, "neon_amber_glow")
    bm_eyes.normal_update()
    m_eyes = bpy.data.meshes.new("BigfootEyesMesh")
    bm_eyes.to_mesh(m_eyes)
    bm_eyes.free()
    obj_eyes = bpy.data.objects.new("Eyes", m_eyes)
    bpy.context.collection.objects.link(obj_eyes)

    root = bpy.data.objects.new("Bigfoot", None)
    root.location = (0, 0, 0)
    bpy.context.collection.objects.link(root)
    export_modular_model(root, [obj_torso, obj_head, obj_arms, obj_legs, obj_eyes], "bigfoot", [
        MODELS_DIR,
        os.path.join(MODELS_DIR, "monsters"),
        os.path.join(MODELS_DIR, "mobs")
    ])

def create_bread():
    """Creates chunky cartoon bread loaf."""
    clear_scene()
    setup_roblox_scene()
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.3))
    bread = bpy.context.active_object
    bread.scale = (0.7, 1.2, 0.45)
    bread.name = "BreadLoaf"
    assign_mesh_uv_color(bread, "copper_bronze")
    finalize_asset(bread, "bread")

def generate_all():
    print("🚀 Starting Blender 5.0 Roblox 3D Asset Generation with Unified Palette...")
    # Weapons & Tools
    create_spear()
    create_torch()
    # 2.2. Interactive / Containers
    create_chest()
    create_parts_chest()
    create_campfire()
    create_ice_crystal()
    create_rabbit_trap()
    create_spike_trap()
    # 2.3. Nature Resources
    create_branches()
    create_stone()
    create_fiber()
    create_planks()
    create_fir_tree()
    # 2.4. Monsters & Enemies
    create_wolf()
    create_yeti()
    create_bigfoot()
    # Supplies
    create_bread()
    print("✅ All Roblox 3D models exported successfully using GamePalette texture!")

if __name__ == "__main__":
    generate_all()

