#!/usr/bin/env python3

"""
File name: algorithm.py
Author: Stephen Barstys (sbarstys)
Created: 02-13-2025
Description: Recommender Algorithm pipeline for generating outfits   
"""

from backend.models.garment import Garment
from backend.models.outfit import Outfit
import algo_utils as utils

def recommend_outfits() -> set[Outfit]:
    """
    Invoked by recommend/ endpoint to generate outfits
    
    Parameters: 
        None

    Returns: 
        set[Outfit]: List of Outfits
    """

    garments = {} # SQL Query
    filtered = filtering_stage(garments)
    ranked = ranking_stage(filtered)
    matched = matching_stage(ranked)
    
    return matched

def filtering_stage(garment_set: set[Garment]) -> set[Garment]:
    """
    Filters out garments based on weather conditions
    
    Parameters: 
        garment_set (set[Garment]): set of all user-owned garments

    Returns: 
        set[Garment]: set of garments filtered by weather suitability
    """
    utils.query_weather_api()
    pass

def ranking_stage(filtered_set: set[Garment]) -> set[Garment]:
    """
    Ranks individual Garments based on custom weighted avg.
    
    Parameters: 
        filtered_set (set[Garment]): garments from previous stage

    Returns: 
        set[Garment]: Set of ranked garments
    """
    pass

def matching_stage(ranked_set: set[Garment]) -> set[Garment]:
    """
    Forms outfits given the ranked garments.
    
    Parameters: 
        ranked_set (set[Garment]): garments from previous stage

    Returns:
        set[Garment]: List of Garments
    """
    pass
