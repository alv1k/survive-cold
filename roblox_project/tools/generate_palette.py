"""
    tools/generate_palette.py
    Generates the unified 256x256 Color Palette Atlas for Survive the Cold.
    Style: Low-Poly / Cartoon (3/10 Realism)
    Layout: 8x8 Grid (64 curated swatches, 32x32 px per swatch)
"""

from PIL import Image, ImageDraw
import os
import json

PALETTE_GRID = [
    # Row 7 (Top: Snow, Ice, Frost, Cyans)
    ["#FFFFFF", "#F0F8FF", "#BAE6FD", "#38BDF8", "#0284C7", "#06B6D4", "#22D3EE", "#00F5D4"],
    # Row 6 (Greys, Slates, Metals, Blacks)
    ["#E2E8F0", "#94A3B8", "#64748B", "#475569", "#334155", "#1E293B", "#0F172A", "#09090B"],
    # Row 5 (Woods, Barks, Planks)
    ["#F7E1D7", "#E5C39E", "#C68B59", "#8C451A", "#5C2E0B", "#3E1E08", "#78716C", "#292524"],
    # Row 4 (Leathers, Twine, Fiber, Soil)
    ["#FEF08A", "#EAB308", "#D4A373", "#A16207", "#713F12", "#543310", "#9A3412", "#38220F"],
    # Row 3 (Greens, Leaves, Pine, Moss, Emerald)
    ["#BEF264", "#84CC16", "#22C55E", "#16A34A", "#15803D", "#14532D", "#10B981", "#4ADE80"],
    # Row 2 (Fire, Heat, Gold, Orange, Embers)
    ["#FEF9C3", "#FDE047", "#FACC15", "#FB923C", "#F97316", "#EA580C", "#D97706", "#FFB703"],
    # Row 1 (Reds, Meats, Berries, Fabrics, Neon)
    ["#FDA4AF", "#FB7185", "#EF4444", "#DC2626", "#991B1B", "#831843", "#FF0055", "#FF0033"],
    # Row 0 (Bottom: Blues, Purples, Mystics, Relics)
    ["#E0F2FE", "#3B82F6", "#1D4ED8", "#1E1B4B", "#A855F7", "#581C87", "#FBBF24", "#F43F5E"],
]

COLOR_NAMES = {
    (0, 7): "snow_pure", (1, 7): "snow_ambient", (2, 7): "ice_light", (3, 7): "ice_glacier",
    (4, 7): "ice_deep", (5, 7): "tech_cyan", (6, 7): "aqua_bright", (7, 7): "neon_cyan_glow",
    
    (0, 6): "slate_light", (1, 6): "steel_light", (2, 6): "stone_slate", (3, 6): "stone_dark",
    (4, 6): "iron_band", (5, 6): "cast_iron", (6, 6): "gunmetal", (7, 6): "pitch_black",
    
    (0, 5): "wood_birch", (1, 5): "wood_pine", (2, 5): "wood_honey_oak", (3, 5): "wood_cedar",
    (4, 5): "wood_walnut", (5, 5): "wood_bark", (6, 5): "wood_weathered", (7, 5): "wood_burnt",
    
    (0, 4): "twine_straw", (1, 4): "fiber_gold", (2, 4): "leather_tan", (3, 4): "leather_warm",
    (4, 4): "leather_dark", (5, 4): "soil_rich", (6, 4): "clay_brick", (7, 4): "soil_dark",
    
    (0, 3): "plant_sprout", (1, 3): "grass_fresh", (2, 3): "leaf_green", (3, 3): "pine_green",
    (4, 3): "pine_dark", (5, 3): "moss_deep", (6, 3): "neon_emerald_glow", (7, 3): "poison_green",
    
    (0, 2): "fire_core", (1, 2): "spark_yellow", (2, 2): "gold_pure", (3, 2): "flame_light",
    (4, 2): "flame_orange", (5, 2): "ember_red", (6, 2): "copper_bronze", (7, 2): "neon_amber_glow",
    
    (0, 1): "pink_soft", (1, 1): "coral_meat", (2, 1): "meat_steak", (3, 1): "soup_can_red",
    (4, 1): "crimson_dark", (5, 1): "sweater_maroon", (6, 1): "neon_red_glow", (7, 1): "pepper_chili",
    
    (0, 0): "sky_pale", (1, 0): "denim_blue", (2, 0): "parka_navy", (3, 0): "midnight_blue",
    (4, 0): "relic_purple", (5, 0): "mystic_void", (6, 0): "relic_gold", (7, 0): "crystal_ruby",
}

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def generate_palette_image(width=256, height=256):
    img = Image.new("RGB", (width, height), "#FFFFFF")
    draw = ImageDraw.Draw(img)
    
    cols = 8
    rows = 8
    cell_w = width // cols
    cell_h = height // rows
    
    for row in range(rows):
        # row in image is 0 at top to 7 at bottom
        # in UV space row 0 is bottom (Y=0)
        grid_row = 7 - row # invert so row 7 is top in image
        for col in range(cols):
            hex_color = PALETTE_GRID[7 - grid_row][col]
            rgb = hex_to_rgb(hex_color)
            
            x0 = col * cell_w
            y0 = row * cell_h
            x1 = x0 + cell_w
            y1 = y0 + cell_h
            
            draw.rectangle([x0, y0, x1, y1], fill=rgb)
            
    return img

def export_palette():
    project_root = r"c:\Users\pc1\Documents\workingdir\roblox_project"
    dirs = [
        os.path.join(project_root, "assets", "textures"),
        os.path.join(project_root, "assets", "models"),
        os.path.join(project_root, "assets", "icons"),
    ]
    
    for d in dirs:
        os.makedirs(d, exist_ok=True)
        
    img = generate_palette_image(256, 256)
    
    for d in dirs:
        p = os.path.join(d, "palette.png")
        img.save(p, "PNG")
        print(f"[OK] Saved palette to: {p}")
        
    # Generate UV mapping helper JSON
    uv_map = {}
    for (col, row), name in COLOR_NAMES.items():
        # UV coordinate: center of cell (col in 0..7, row in 0..7)
        u = (col + 0.5) / 8.0
        v = (row + 0.5) / 8.0
        hex_val = PALETTE_GRID[7 - row][col]
        uv_map[name] = {
            "col": col,
            "row": row,
            "u": round(u, 5),
            "v": round(v, 5),
            "hex": hex_val,
            "rgb": [c / 255.0 for c in hex_to_rgb(hex_val)]
        }
        
    json_path = os.path.join(project_root, "assets", "palette_uv_map.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(uv_map, f, indent=2, ensure_ascii=False)
    print(f"[OK] Saved UV mapping table to: {json_path}")

if __name__ == "__main__":
    export_palette()
