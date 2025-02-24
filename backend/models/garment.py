"""
File name: garment.py
Author: Stephen Barstys (sbarstys)
Created: 02-13-2025
Description: Defines a garment object according to database schema  
"""

from dataclasses import dataclass


@dataclass
class Garment:
    garm_id: int
    pass
