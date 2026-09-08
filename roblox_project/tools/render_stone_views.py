"""
    tools/render_stone_views.py
    Renders of the new blocky/cubic stone model
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
iso_img = os.path.join(art_brain_dir, "stone_blocky_iso.png")
front_img = os.path.join(art_brain_dir, "stone_blocky_front.png")
top_img = os.path.join(art_brain_dir, "stone_blocky_top.png")

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

# Studio Background
world = bpy.context.scene.world
if not world:
    world = bpy.data.worlds.new("StudioWorld")
    bpy.context.scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs['Color'].default_value = (0.24, 0.26, 0.30, 1.0)
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
key_light_data.color = (1.0, 0.98, 0.95)
key_light = bpy.data.objects.new("KeyLight", key_light_data)
key_light.location = (-6, -8, 10)
key_light.rotation_euler = (math.radians(45), math.radians(20), math.radians(-35))
bpy.context.collection.objects.link(key_light)

# Fill Light
fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
fill_light_data.energy = 2.8
fill_light_data.color = (0.85, 0.92, 1.0)
fill_light = bpy.data.objects.new("FillLight", fill_light_data)
fill_light.location = (8, -6, 8)
fill_light.rotation_euler = (math.radians(50), math.radians(-25), math.radians(40))
bpy.context.collection.objects.link(fill_light)

# Rim Light
rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
rim_light_data.energy = 3.5
rim_light_data.color = (1.0, 0.96, 0.90)
rim_light = bpy.data.objects.new("RimLight", rim_light_data)
rim_light.location = (0, 10, 8)
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

target = (0, 0, 0.8)

# 1. Isometric View
point_camera_at(cam, target, (-4.2, -5.2, 3.8))
scene.render.filepath = iso_img
bpy.ops.render.render(write_still=True)
print("Rendered Blocky Stone ISO:", iso_img)

# 2. Front View
point_camera_at(cam, target, (0.0, -6.5, 1.8))
scene.render.filepath = front_img
bpy.ops.render.render(write_still=True)
print("Rendered Blocky Stone Front:", front_img)

# 3. Top-Angle View
point_camera_at(cam, target, (-2.5, -3.5, 5.5))
scene.render.filepath = top_img
bpy.ops.render.render(write_still=True)
print("Rendered Blocky Stone Top:", top_img)
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
