"""
tools/run_blender_action.py
Executes Python code in Blender 5.0 via BlenderMCP live socket on port 9876.
"""

import socket
import json
import base64
import os
import sys

PORT = 9876
HOST = "127.0.0.1"

def send_blender_command(command_type, params=None, timeout=20.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    s.connect((HOST, PORT))
    
    cmd = {
        "type": command_type,
        "params": params or {}
    }
    
    s.sendall(json.dumps(cmd).encode('utf-8'))
    
    chunks = []
    while True:
        try:
            chunk = s.recv(8192)
            if not chunk:
                break
            chunks.append(chunk)
            data = b"".join(chunks)
            try:
                res = json.loads(data.decode('utf-8'))
                s.close()
                return res
            except json.JSONDecodeError:
                continue
        except socket.timeout:
            print("Socket timed out waiting for complete response")
            break
            
    s.close()
    if chunks:
        data = b"".join(chunks)
        try:
            return json.loads(data.decode('utf-8'))
        except:
            return {"status": "error", "message": "Incomplete response: " + data.decode('utf-8', errors='ignore')}
    return {"status": "error", "message": "No data received"}

def main():
    code = """
import sys
import os

tools_path = r'c:\\Users\\pc1\\Documents\\workingdir\\roblox_project\\tools'
if tools_path not in sys.path:
    sys.path.insert(0, tools_path)

import blender_pipeline
import importlib
importlib.reload(blender_pipeline)

blender_pipeline.create_parts()
print("PARTS GENERATION AND EXPORT COMPLETED SUCCESSFULLY")
"""

    print("Connecting to Blender on port 9876...")
    res = send_blender_command("execute_code", {"code": code})
    print("Execution Result:", json.dumps(res, indent=2))
    
    # Save viewport screenshot
    print("Capturing viewport screenshot...")
    shot_res = send_blender_command("get_viewport_screenshot", {})
    if shot_res.get("status") == "success":
        img_b64 = shot_res.get("result", {}).get("image", "")
        if img_b64:
            artifact_dir = r"C:\Users\pc1\.gemini\antigravity-ide\brain\9ac5d23e-aec2-497c-a2cd-138e3310c187"
            out_img = os.path.join(artifact_dir, "parts_viewport.png")
            with open(out_img, "wb") as f:
                f.write(base64.b64decode(img_b64))
            print(f"Viewport screenshot saved to: {out_img}")
    else:
        print("Screenshot status:", shot_res)

if __name__ == "__main__":
    main()
