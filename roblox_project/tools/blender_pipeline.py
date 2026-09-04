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

def finalize_asset(obj, name, out_obj=True, out_fbx=True):
    """Assigns palette material, flat shading, and exports."""
    mat = get_or_create_palette_mat()
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    bpy.ops.object.shade_flat()
    
    if out_obj:
        validate_and_export(obj, os.path.join(MODELS_DIR, f"{name}.obj"), "OBJ")
    if out_fbx:
        validate_and_export(obj, os.path.join(MODELS_DIR, f"{name}.fbx"), "FBX")

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
    """Creates supply chest with lid, wood body and gold lock."""
    clear_scene()
    setup_roblox_scene()
    
    # Base Box
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.7))
    base = bpy.context.active_object
    base.scale = (1.8, 1.2, 0.7)
    base.name = "ChestBase"
    assign_mesh_uv_color(base, "wood_honey_oak")
    
    # Lid
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.6))
    lid = bpy.context.active_object
    lid.scale = (1.9, 1.3, 0.3)
    lid.name = "ChestLid"
    assign_mesh_uv_color(lid, "wood_cedar")
    
    # Lock
    bpy.ops.mesh.primitive_cube_add(size=0.3, location=(0, -0.65, 1.2))
    lock = bpy.context.active_object
    lock.scale = (0.8, 0.3, 0.8)
    lock.name = "Lock"
    assign_mesh_uv_color(lock, "gold_pure")
    
    parts = [base, lid, lock]
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    
    chest = bpy.context.active_object
    chest.name = "SupplyChest"
    finalize_asset(chest, "chest")

def create_stone_boulder():
    """Creates slate rock boulder with snow cap."""
    clear_scene()
    setup_roblox_scene()
    
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.2, location=(0, 0, 0.8))
    rock = bpy.context.active_object
    rock.scale = (1.4, 1.1, 0.8)
    rock.name = "StoneBoulder"
    assign_mesh_uv_color(rock, "stone_slate")
    finalize_asset(rock, "stone")

def create_bread():
    """Creates chunky cartoon bread loaf."""
    clear_scene()
    setup_roblox_scene()
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.3))
    bread = bpy.context.active_object
    bread.scale = (0.7, 1.2, 0.45)
    bread.name = "BreadLoaf"
    assign_mesh_uv_color(bread, "copper_bronze") # Golden baked crust
    finalize_asset(bread, "bread")

def generate_all():
    print("🚀 Starting Blender 5.0 Roblox 3D Asset Generation with Unified Palette...")
    create_spear()
    create_torch()
    create_chest()
    create_stone_boulder()
    create_bread()
    print("✅ All starter 3D models exported successfully using GamePalette texture!")

if __name__ == "__main__":
    generate_all()
