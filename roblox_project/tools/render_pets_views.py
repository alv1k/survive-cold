"""
    tools/render_pets_views.py
    Renders 3-angle verification shots for Fox and BearCub in Blender 5.0
"""

import socket
import json
import os

PORT = 9876
HOST = "127.0.0.1"

SCRIPT = r"""
import bpy
import math
import os
from mathutils import Vector, Euler

BRAIN_DIR = r"C:\Users\pc1\.gemini\antigravity-ide\brain\d766dd16-21c3-45ee-9fb6-b500cd9314ac"
os.makedirs(BRAIN_DIR, exist_ok=True)

def render_pet(blend_path, pet_name, center_z=0.8):
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    
    # Ensure palette texture is loaded
    tex_path = r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\textures\palette.png"
    mat = bpy.data.materials.get("GamePalette")
    if mat and mat.use_nodes:
        tex_node = mat.node_tree.nodes.get("Image Texture")
        if not tex_node:
            for n in mat.node_tree.nodes:
                if n.type == 'TEX_IMAGE':
                    tex_node = n
                    break
        if tex_node and os.path.exists(tex_path):
            img = bpy.data.images.get("palette.png")
            if not img:
                img = bpy.data.images.load(tex_path)
            tex_node.image = img

    # Lighting
    world = bpy.context.scene.world
    if world:
        world.use_nodes = True
        bg = world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs['Color'].default_value = (0.06, 0.09, 0.15, 1.0)
            bg.inputs['Strength'].default_value = 1.0

    sun_data = bpy.data.lights.new(name="SunLight", type='SUN')
    sun_data.energy = 4.0
    sun_data.color = (1.0, 0.95, 0.9)
    sun_obj = bpy.data.objects.new("SunLight", sun_data)
    sun_obj.rotation_euler = (math.radians(45), math.radians(25), math.radians(-35))
    bpy.context.collection.objects.link(sun_obj)

    fill_data = bpy.data.lights.new(name="FillLight", type='POINT')
    fill_data.energy = 120.0
    fill_data.color = (0.7, 0.85, 1.0)
    fill_obj = bpy.data.objects.new("FillLight", fill_data)
    fill_obj.location = (-3.0, -3.0, 3.0)
    bpy.context.collection.objects.link(fill_obj)

    cam_data = bpy.data.cameras.new(name="RenderCam")
    cam_data.lens = 42
    cam_obj = bpy.data.objects.new("RenderCam", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    scene = bpy.context.scene
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.image_settings.file_format = 'PNG'

    views = {
        "iso": (Vector((3.2, -3.5, 2.6)), Vector((0, 0, center_z))),
        "front": (Vector((0, -4.2, center_z + 0.1)), Vector((0, 0, center_z))),
        "side": (Vector((-4.2, 0, center_z + 0.1)), Vector((0, 0, center_z)))
    }

    for vname, (cpos, tpos) in views.items():
        cam_obj.location = cpos
        direction = tpos - cpos
        rot_quat = direction.to_track_quat('-Z', 'Y')
        cam_obj.rotation_euler = rot_quat.to_euler()
        
        out_path = os.path.join(BRAIN_DIR, f"{pet_name}_{vname}.png")
        scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {pet_name} {vname} -> {out_path}")

render_pet(r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models\pets\fox.blend", "fox", center_z=0.9)
render_pet(r"c:\Users\pc1\Documents\workingdir\roblox_project\assets\models\pets\bearcub.blend", "bearcub", center_z=0.9)
"""

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(30.0)
    s.connect((HOST, PORT))
    cmd = {"type": "execute_code", "params": {"code": SCRIPT}}
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
                print("Render response:", json.dumps(res, indent=2))
                return
            except json.JSONDecodeError:
                continue
        except socket.timeout:
            break
    s.close()

if __name__ == "__main__":
    main()
