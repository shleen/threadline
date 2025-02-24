"""
File name: algo_utils.py
Author: Stephen Barstys (sbarstys)
Created: 02-13-2025
Description: Helper utilities used by recommender algorithm   
"""

from backend.models.color import CIELAB
from backend.models.garment import Garment
from enum import Enum
from typing import Dict
import numpy as np

class GarmType(Enum):
    SHOES = 0,
    TOP = 1,
    PANTS = 2



def query_weather_api(lat: float, long: float) -> None:
    """
    Learns current weather conditions from API call

    Params:
        lat (float): Device latitude coordinate
        long (float): Device longitude coordinate

    Returns:
    """
    pass


def compare_colors(c1: CIELAB, c2: CIELAB) -> float:
    """
    Compares how similar two CIELAB colors are through Euclidean distance.
    The difference between two colors is linear in Euclidean distance
    
    Parameters: 
        c1 (CIELAB):  
        c2 (CIELAB):

    Returns:
        float: Euclidean distance between colors representing similarity
    """

    return np.linalg.norm(c1.to_np() - c2.to_np())


def compute_ranking(garment: Garment, params: Dict[str, float]) -> float:
    pass