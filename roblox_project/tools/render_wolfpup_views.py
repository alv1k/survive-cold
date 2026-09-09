"""
    tools/render_wolfpup_views.py
    Renders Isometric, Front, and Side views of the 3D Friendly Wolf Pup in Blender 5.0.
"""

import socket
import json
import os
import sys

PORT = 9876
HOST = "127.0.0.1"

artifact_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\d766dd16-21c3-45ee-9fb6-b500cd9314ac"
os.makedirs(artifact_dir, exist_ok=True)

RENDER_SCRIPT = rf"""
import bpy
import os
import math
import mathutils
from mathutils import Vector, Euler

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 800
scene.render.resolution_y = 600
scene.render.film_transparent = True

# World lighting
world = scene.world or bpy.data.worlds.new("World")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs['Color'].default_value = (0.04, 0.07, 0.11, 1.0)
    bg.inputs['Strength'].default_value = 1.0

# Remove old camera & lights
for obj in list(scene.objects):
    if obj.type in ('CAMERA', 'LIGHT'):
        bpy.data.objects.remove(obj, do_unlink=True)

# Key Light
key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
key_light_data.energy = 4.5
key_light_data.color = (1.0, 0.97, 0.92)
key_light = bpy.data.objects.new(name="KeyLight", object_data=key_light_data)
key_light.rotation_euler = (math.radians(50), math.radians(20), math.radians(-35))
bpy.context.collection.objects.link(key_light)

# Fill Light (Cool blue ambient)
fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
fill_light_data.energy = 2.5
fill_light_data.color = (0.6, 0.8, 1.0)
fill_light = bpy.data.objects.new(name="FillLight", object_data=fill_light_data)
fill_light.rotation_euler = (math.radians(30), math.radians(-40), math.radians(140))
bpy.context.collection.objects.link(fill_light)

# Camera
cam_data = bpy.data.cameras.new(name="RenderCam")
cam_data.lens = 50
cam_obj = bpy.data.objects.new(name="RenderCam", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)
scene.camera = cam_obj

target = Vector((0, -0.2, 0.9))

def aim_cam(pos, tgt=target):
    cam_obj.location = pos
    direction = tgt - pos
    rot_quat = direction.to_track_quat('-Z', 'Y')
    cam_obj.rotation_euler = rot_quat.to_euler()

art_dir = r"{artifact_dir}"

# 1. Isometric View
aim_cam(Vector((-2.8, -3.2, 2.2)), Vector((0, -0.2, 0.9)))
scene.render.filepath = os.path.join(art_dir, "wolfpup_iso.png")
bpy.ops.render.render(write_still=True)

# 2. Front View (Cute Face)
aim_cam(Vector((0, -3.4, 1.25)), Vector((0, -0.6, 1.25)))
scene.render.filepath = os.path.join(art_dir, "wolfpup_front.png")
bpy.ops.render.render(write_still=True)

# 3. Side View
aim_cam(Vector((-3.6, 0, 1.0)), Vector((0, 0, 0.9)))
scene.render.filepath = os.path.join(art_dir, "wolfpup_side.png")
bpy.ops.render.render(write_still=True)

print("WolfPup Renders finished successfully!")
"""

def send_blender_code(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(35.0)
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
    print("Rendering WolfPup viewpoints...")
    res = send_blender_code(RENDER_SCRIPT)
    print("Render Result:", json.dumps(res, indent=2))

if __name__ == "__main__":
    main()
