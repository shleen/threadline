import math

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
