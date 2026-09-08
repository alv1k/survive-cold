"""
    tools/render_food_showcase.py
    Showcase table render of all 7 3D food items
"""
import socket
import json
import os

PORT = 9876
HOST = "127.0.0.1"

RENDER_CODE = r"""
import bpy
import os
import math
from mathutils import Vector, Euler

art_brain_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\091bceeb-504a-4a50-a7df-e1a798f09f40"
showcase_img = os.path.join(art_brain_dir, "food_showcase_all.png")

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Studio World
world = bpy.context.scene.world
if not world:
    world = bpy.data.worlds.new("StudioWorld")
    bpy.context.scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs['Color'].default_value = (0.20, 0.22, 0.26, 1.0)
    bg_node.inputs['Strength'].default_value = 1.0

# 3-point lighting
key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
key_light_data.energy = 4.2
key_light_data.color = (1.0, 0.98, 0.94)
key_light = bpy.data.objects.new("KeyLight", key_light_data)
key_light.location = (-10, -15, 15)
key_light.rotation_euler = (math.radians(45), math.radians(20), math.radians(-35))
bpy.context.collection.objects.link(key_light)

fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
fill_light_data.energy = 2.5
fill_light_data.color = (0.85, 0.92, 1.0)
fill_light = bpy.data.objects.new("FillLight", fill_light_data)
fill_light.location = (15, -10, 10)
fill_light.rotation_euler = (math.radians(50), math.radians(-25), math.radians(40))
bpy.context.collection.objects.link(fill_light)

rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
rim_light_data.energy = 3.2
rim_light_data.color = (1.0, 0.95, 0.85)
rim_light = bpy.data.objects.new("RimLight", rim_light_data)
rim_light.location = (0, 15, 12)
rim_light.rotation_euler = (math.radians(-50), 0, math.radians(180))
bpy.context.collection.objects.link(rim_light)

# Import all 7 OBJs and place them in a showcase row/table
food_dir = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models\food"
items = [
    ("bar.obj", (-3.6, 0.0, 0.0), 0),
    ("bread.obj", (-2.4, 0.0, 0.0), 0),
    ("chips.obj", (-1.2, 0.0, 0.0), 0),
    ("soup.obj", (0.0, 0.0, 0.0), 0),
    ("pepper.obj", (1.2, 0.0, 0.0), 0),
    ("coffee.obj", (2.4, 0.0, 0.0), 0),
    ("steak.obj", (3.6, 0.0, 0.0), 0)
]

for fname, pos, rot in items:
    fpath = os.path.join(food_dir, fname)
    if os.path.exists(fpath):
        bpy.ops.wm.obj_import(filepath=fpath)
        imported = bpy.context.selected_objects[0]
        imported.location = pos

# Camera
cam = bpy.data.objects.get("Camera")
if not cam:
    cam_data = bpy.data.cameras.new(name="Camera")
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.collection.objects.link(cam)
scene.camera = cam

def point_camera_at(cam_obj, target_pos, cam_pos):
    cam_obj.location = cam_pos
    direction = Vector(target_pos) - Vector(cam_pos)
    rot_quat = direction.to_track_quat('-Z', 'Y')
    cam_obj.rotation_euler = rot_quat.to_euler()

point_camera_at(cam, (0.0, 0.0, 0.4), (0.0, -10.5, 4.2))
scene.render.filepath = showcase_img
bpy.ops.render.render(write_still=True)
print("Rendered Food Showcase:", showcase_img)
"""

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((HOST, PORT))
    cmd = {"type": "execute_code", "params": {"code": RENDER_CODE}}
    s.sendall(json.dumps(cmd).encode('utf-8'))
    print(s.recv(4096).decode('utf-8'))
    s.close()

if __name__ == "__main__":
    main()
