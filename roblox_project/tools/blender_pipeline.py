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
    """Clears all objects from current scene."""
    bpy.ops.wm.read_factory_settings(use_empty=True)

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
# Procedural 3D Generators for Starter Assets
# ==============================================================================

def create_spear():
    """Creates low-poly hunting spear (handle + slate tip)."""
    clear_scene()
    setup_roblox_scene()
    
    # Wooden shaft (Handle centered at 0,0,0)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=4.2, location=(0, 0, 1.2))
    shaft = bpy.context.active_object
    shaft.name = "Shaft"
    
    # Slate blade tip
    bpy.ops.mesh.primitive_cone_add(radius1=0.25, radius2=0.02, depth=1.2, location=(0, 0, 3.8))
    blade = bpy.context.active_object
    blade.scale = (0.2, 1.0, 1.0)
    blade.name = "Blade"
    
    # Join into single spear
    bpy.context.view_layer.objects.active = shaft
    shaft.select_set(True)
    blade.select_set(True)
    bpy.ops.object.join()
    
    spear = bpy.context.active_object
    spear.name = "Spear"
    validate_and_export(spear, os.path.join(MODELS_DIR, "spear.obj"), "OBJ")

def create_torch():
    """Creates survival wooden torch."""
    clear_scene()
    setup_roblox_scene()
    
    # Stick
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.4, location=(0, 0, 0.8))
    stick = bpy.context.active_object
    stick.name = "Stick"
    
    # Cloth head wrap
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.6, location=(0, 0, 1.9))
    head = bpy.context.active_object
    head.name = "HeadWrap"
    
    bpy.context.view_layer.objects.active = stick
    stick.select_set(True)
    head.select_set(True)
    bpy.ops.object.join()
    
    torch = bpy.context.active_object
    torch.name = "Torch"
    validate_and_export(torch, os.path.join(MODELS_DIR, "torch.obj"), "OBJ")

def create_chest():
    """Creates supply chest with lid and lock."""
    clear_scene()
    setup_roblox_scene()
    
    # Base Box (resting on Y=0)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.7))
    base = bpy.context.active_object
    base.scale = (1.8, 1.2, 0.7)
    base.name = "ChestBase"
    
    # Lid
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.6))
    lid = bpy.context.active_object
    lid.scale = (1.9, 1.3, 0.3)
    lid.name = "ChestLid"
    
    # Lock
    bpy.ops.mesh.primitive_cube_add(size=0.3, location=(0, -0.65, 1.2))
    lock = bpy.context.active_object
    lock.scale = (0.8, 0.3, 0.8)
    lock.name = "Lock"
    
    bpy.context.view_layer.objects.active = base
    base.select_set(True)
    lid.select_set(True)
    lock.select_set(True)
    bpy.ops.object.join()
    
    chest = bpy.context.active_object
    chest.name = "SupplyChest"
    validate_and_export(chest, os.path.join(MODELS_DIR, "chest.obj"), "OBJ")

def create_stone_boulder():
    """Creates slate rock boulder with snow cap."""
    clear_scene()
    setup_roblox_scene()
    
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.2, location=(0, 0, 0.8))
    rock = bpy.context.active_object
    rock.scale = (1.4, 1.1, 0.8)
    rock.name = "StoneBoulder"
    validate_and_export(rock, os.path.join(MODELS_DIR, "stone.obj"), "OBJ")

def create_bread():
    """Creates bread loaf item."""
    clear_scene()
    setup_roblox_scene()
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.3))
    bread = bpy.context.active_object
    bread.scale = (0.7, 1.2, 0.45)
    bread.name = "BreadLoaf"
    validate_and_export(bread, os.path.join(MODELS_DIR, "bread.obj"), "OBJ")

def generate_all():
    print("🚀 Starting Blender 5.0 Roblox 3D Asset Generation...")
    create_spear()
    create_torch()
    create_chest()
    create_stone_boulder()
    create_bread()
    print("✅ All starter 3D models exported successfully to assets/models/!")

if __name__ == "__main__":
    generate_all()
