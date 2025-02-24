"""
File name: color.py
Author: Stephen Barstys (sbarstys)
Created: 02-13-2025
Description: Representations of colors in RGB and CIELAB color spaces
"""

from dataclasses import dataclass
from colormath.color_objects import sRGBColor, LabColor
from colormath.color_conversions import convert_color 
import numpy as np


@dataclass
class CIELAB:
    """Dataclass to store colors in CIELAB color space"""

    l_star_: float
    a_star_: float
    b_star_: float

    def to_np(self) -> np.array:
        """
        Represent CIELAB coordinates as numpy arrays

        Parameters:
            None

        Return:
            np.array: vector in numpy array form for CIELAB color
        """

        return np.array(self.l_star_, self.a_star_, self.b_star_)

@dataclass
class RGB:
    """Dataclass to store colors in RGB color space"""

    red_: int
    green_: int
    blue_: int

    def to_cielab(self) -> CIELAB:
        """
        Convert RGB color coordinate to CIELAB color space
        
        Parameters: 
            None

        Returns: 
            CIELAB: Color represented int CIELAB space
        """

        NORM_CONST = 255
        red_norm = self.red_ / NORM_CONST
        green_norm = self.green_ / NORM_CONST
        blue_norm = self.blue_ / NORM_CONST

        srgb_color = sRGBColor(red_norm, green_norm, blue_norm)
        lab_color = convert_color(srgb_color, LabColor);

        return CIELAB(*lab_color)
