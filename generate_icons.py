#!/usr/bin/env python3
"""
Run this script once to generate placeholder icons for the Chrome extension.
Usage: python3 generate_icons.py
"""
from PIL import Image, ImageDraw, ImageFont
import os

SIZES = [16, 48, 128]
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons")

def create_icon(size):
    img = Image.new("RGBA", (size, size), (37, 99, 235, 255))
    draw = ImageDraw.Draw(img)

    center = size // 2
    radius = int(size * 0.35)

    draw.ellipse(
        [center - radius, center - radius, center + radius, center + radius],
        fill=(255, 255, 255, 255)
    )

    # Minimum font size to avoid PIL errors
    font_size = max(8, int(size * 0.3))
    font = None
    
    # Try to load a TrueType font
    for font_path in [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]:
        try:
            font = ImageFont.truetype(font_path, font_size)
            break
        except (OSError, IOError):
            continue
    
    # Fallback: use default font with textsize (works for bitmap fonts)
    if font is None:
        font = ImageFont.load_default()

    text = "AI"
    
    # Use textsize for bitmap fonts, textbbox for TrueType
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
    except (AttributeError, OSError):
        # Fallback for bitmap/default font
        text_w, text_h = draw.textsize(text, font=font)
    
    draw.text((center - text_w // 2, center - text_h // 2 - 1), text, fill=(37, 99, 235, 255), font=font)

    return img

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for size in SIZES:
        icon = create_icon(size)
        path = os.path.join(OUTPUT_DIR, f"icon{size}.png")
        icon.save(path)
        print(f"Created {path}")
    print("Done! Icons generated.")
