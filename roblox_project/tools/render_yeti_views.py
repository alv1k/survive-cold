"""
    tools/render_yeti_views.py
    Accurately aimed camera renders of the 4x Yeti model
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

artifact_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\091bceeb-504a-4a50-a7df-e1a798f09f40"
iso_img = os.path.join(artifact_dir, "yeti_assembled_iso.png")
front_img = os.path.join(artifact_dir, "yeti_assembled_front.png")
side_img = os.path.join(artifact_dir, "yeti_assembled_side.png")

scene = bpy.context.scene
scene.render.resolution_x = 1280
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'

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

target = (0, 0, 8.0)

# 1. Isometric View
point_camera_at(cam, target, (-22.0, -26.0, 14.0))
scene.render.filepath = iso_img
bpy.ops.render.render(write_still=True)
print("Rendered Yeti ISO:", iso_img)

# 2. Front View
point_camera_at(cam, target, (0.0, -32.0, 8.5))
scene.render.filepath = front_img
bpy.ops.render.render(write_still=True)
print("Rendered Yeti Front:", front_img)

# 3. Side View
point_camera_at(cam, target, (-32.0, 0.0, 8.5))
scene.render.filepath = side_img
bpy.ops.render.render(write_still=True)
print("Rendered Yeti Side:", side_img)
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
