import math
from .models import Clothing

def lab_to_hcl(l, a, b):
    """Convert CIELAB color to HCL (Hue, Chroma, Luminance)"""
    h = math.atan2(b, a) * (180/math.pi)  # Convert to degrees
    if h < 0:
        h += 360
    c = math.sqrt(a*a + b*b)
    return (h, c, l)


def hcl_to_lab(h, c, l):
    """Convert HCL color back to CIELAB"""
    h_rad = h * (math.pi/180)  # Convert to radians
    a = c * math.cos(h_rad)
    b = c * math.sin(h_rad)
    return (l, a, b)

# Converts RGB value into CIELAB
def rgb_to_lab(rgb):
    # Step 1: Convert RGB to XYZ
    r, g, b = [x / 255.0 for x in rgb]

    # Apply the inverse gamma correction
    r = r / 12.92 if r <= 0.04045 else ((r + 0.055) / 1.055) ** 2.4
    g = g / 12.92 if g <= 0.04045 else ((g + 0.055) / 1.055) ** 2.4
    b = b / 12.92 if b <= 0.04045 else ((b + 0.055) / 1.055) ** 2.4

    # Convert to XYZ
    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

    # Scale to 100
    x *= 100
    y *= 100
    z *= 100

    # Step 2: Convert XYZ to CIELAB
    ref_x, ref_y, ref_z = 95.047, 100.000, 108.883

    x = x / ref_x
    y = y / ref_y
    z = z / ref_z

    x = x ** (1/3) if x > 0.008856 else (x * 7.787 + 16/116)
    y = y ** (1/3) if y > 0.008856 else (y * 7.787 + 16/116)
    z = z ** (1/3) if z > 0.008856 else (z * 7.787 + 16/116)

    l = max(0, min(100, (116 * y) - 16))
    a = (x - y) * 500
    b = (y - z) * 200

    return (l, a, b)

def lab_to_rgb(lab):
    # Constants
    ref_x =  0.95047
    ref_y =  1.00000
    ref_z =  1.08883

    # Unpack the lab values
    l, a, b = lab

    # Normalize L, a, b to the range [0, 100] for L, and [-128, 128] for a, b
    fy = (l + 16) / 116
    fx = a / 500 + fy
    fz = fy - b / 200

    # Convert to XYZ
    x = ref_x * (fx ** 3 if fx ** 3 > 0.008856 else (fx - 16 / 116) / 7.787)
    y = ref_y * (fy ** 3 if fy ** 3 > 0.008856 else (fy - 16 / 116) / 7.787)
    z = ref_z * (fz ** 3 if fz ** 3 > 0.008856 else (fz - 16 / 116) / 7.787)

    # Convert to RGB
    rgb = [x * 3.2406 - y * 1.5372 - z * 0.4986,
           -x * 0.9689 + y * 1.8758 + z * 0.0415,
           x * 0.0556 - y * 0.2040 + z * 1.0570]

    # Gamma correction and clamping to [0, 255]
    for i in range(3):
        rgb[i] = 255 * (rgb[i] if rgb[i] <= 0.0031308 else (1.055 * (rgb[i] ** (1/2.4))) - 0.055)
        rgb[i] = max(0, min(255, round(rgb[i])))

    return tuple(rgb)

def pop_base_garments(ranked):
    clothes = []
    for clothing_type in [Clothing.ClothingType.TOP, Clothing.ClothingType.BOTTOM, Clothing.ClothingType.SHOES]:
        garment = ranked[clothing_type].pop()
        clothes.append({"id": garment["id"], "img": garment["img_filename"], "type": clothing_type})
    return clothes

def get_base_weather(ranked):
    if ranked[Clothing.ClothingType.TOP]:
        return ranked[Clothing.ClothingType.TOP][0].get("weather")
    return None

def add_layerable_top(ranked, clothes):
    layerable_tops = [g for g in ranked[Clothing.ClothingType.TOP] if g.get("layerable", False)]
    if layerable_tops:
        layer = layerable_tops.pop()
        clothes.append({
            "id": layer["id"],
            "img": layer["img_filename"],
            "type": Clothing.ClothingType.TOP
        })

def add_outerwear(ranked, clothes):
    if ranked[Clothing.ClothingType.OUTERWEAR]:
        outerwear = ranked[Clothing.ClothingType.OUTERWEAR].pop()
        clothes.append({
            "id": outerwear["id"],
            "img": outerwear["img_filename"],
            "type": Clothing.ClothingType.OUTERWEAR
        })
