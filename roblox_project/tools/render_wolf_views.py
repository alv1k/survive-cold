"""
    Render multiple angles of the multi-part wolf model in Blender 5.0
"""
import socket
import json
import os

PORT = 9876
HOST = "127.0.0.1"

RENDER_CODE = r"""
import bpy
import math
import os

artifact_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\091bceeb-504a-4a50-a7df-e1a798f09f40"
iso_img = os.path.join(artifact_dir, "wolf_assembled_iso.png")
front_img = os.path.join(artifact_dir, "wolf_assembled_front.png")
side_img = os.path.join(artifact_dir, "wolf_assembled_side.png")

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

# Set up clean camera and lighting if needed
cam = bpy.data.objects.get("Camera")
if not cam:
    cam_data = bpy.data.cameras.new(name="Camera")
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.collection.objects.link(cam)
scene.camera = cam

sun = bpy.data.objects.get("Sun")
if not sun:
    sun_data = bpy.data.lights.new(name="Sun", type='SUN')
    sun_data.energy = 3.5
    sun = bpy.data.objects.new("Sun", sun_data)
    bpy.context.collection.objects.link(sun)
    sun.location = (4.0, -5.0, 6.0)
    sun.rotation_euler = (math.radians(52), math.radians(12), math.radians(-38))

# 1. Isometric View
cam.location = (-3.2, -4.2, 2.8)
cam.rotation_euler = (math.radians(66), 0, math.radians(-38))
scene.render.filepath = iso_img
bpy.ops.render.render(write_still=True)
print("Rendered ISO:", iso_img)

# 2. Front View
cam.location = (0.0, -3.8, 1.3)
cam.rotation_euler = (math.radians(80), 0, 0)
scene.render.filepath = front_img
bpy.ops.render.render(write_still=True)
print("Rendered Front:", front_img)

# 3. Side View
cam.location = (-4.2, 0.0, 1.2)
cam.rotation_euler = (math.radians(82), 0, math.radians(-90))
scene.render.filepath = side_img
bpy.ops.render.render(write_still=True)
print("Rendered Side:", side_img)
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
