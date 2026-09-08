"""
    tools/render_bigfoot_views.py
    Accurately aimed camera renders of the 4x Bigfoot model with vibrant lighting
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

artifact_dir = r"C:\Users\pc1\Documents\workingdir\roblox_project\.agents\skills\blender-roblox" # scratch
art_brain_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\091bceeb-504a-4a50-a7df-e1a798f09f40"
iso_img = os.path.join(art_brain_dir, "bigfoot_assembled_iso.png")
front_img = os.path.join(art_brain_dir, "bigfoot_assembled_front.png")
side_img = os.path.join(art_brain_dir, "bigfoot_assembled_side.png")

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

# Set world background to clean neutral studio gray
world = bpy.context.scene.world
if not world:
    world = bpy.data.worlds.new("StudioWorld")
    bpy.context.scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs['Color'].default_value = (0.22, 0.24, 0.28, 1.0)
    bg_node.inputs['Strength'].default_value = 1.2

# Setup 3-point lighting
for l in list(bpy.data.lights):
    bpy.data.lights.remove(l, do_unlink=True)
for o in list(bpy.data.objects):
    if o.type == 'LIGHT':
        bpy.data.objects.remove(o, do_unlink=True)

# Key Light
key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
key_light_data.energy = 4.5
key_light_data.color = (1.0, 0.98, 0.94)
key_light = bpy.data.objects.new("KeyLight", key_light_data)
key_light.location = (-15, -20, 25)
key_light.rotation_euler = (math.radians(45), math.radians(20), math.radians(-35))
bpy.context.collection.objects.link(key_light)

# Fill Light (Front-Right)
fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
fill_light_data.energy = 2.8
fill_light_data.color = (0.85, 0.90, 1.0)
fill_light = bpy.data.objects.new("FillLight", fill_light_data)
fill_light.location = (20, -15, 18)
fill_light.rotation_euler = (math.radians(50), math.radians(-25), math.radians(40))
bpy.context.collection.objects.link(fill_light)

# Rim/Back Light (Behind)
rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
rim_light_data.energy = 3.5
rim_light_data.color = (1.0, 0.95, 0.85)
rim_light = bpy.data.objects.new("RimLight", rim_light_data)
rim_light.location = (0, 25, 20)
rim_light.rotation_euler = (math.radians(-50), 0, math.radians(180))
bpy.context.collection.objects.link(rim_light)

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

target = (0, 0, 7.5)

# 1. Isometric View
point_camera_at(cam, target, (-20.0, -24.0, 13.0))
scene.render.filepath = iso_img
bpy.ops.render.render(write_still=True)
print("Rendered Bigfoot ISO:", iso_img)

# 2. Front View
point_camera_at(cam, target, (0.0, -30.0, 8.0))
scene.render.filepath = front_img
bpy.ops.render.render(write_still=True)
print("Rendered Bigfoot Front:", front_img)

# 3. Side View
point_camera_at(cam, target, (-30.0, 0.0, 8.0))
scene.render.filepath = side_img
bpy.ops.render.render(write_still=True)
print("Rendered Bigfoot Side:", side_img)
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
