#!/usr/bin/env python3

"""
File name: algorithm.py
Author: Stephen Barstys (sbarstys)
Created: 02-13-2025
Description: Recommender Algorithm pipeline for generating outfits   
"""

from backend.models.garment import Garment
from backend.models.outfit import Outfit
from typing import Dict, Set
import algo_utils as utils


def recommend_outfits() -> Set[Outfit]:
    """
    Invoked by recommend/ endpoint to generate outfits
    
    Parameters: 
        None

    Returns: 
        set[Outfit]: List of Outfits
    """

    filtered = filtering_stage()
    ranked = ranking_stage(filtered)
    return matching_stage(ranked)


def filtering_stage() -> Dict[str, Set[Garment]]:
    """
    Filters out garments based on weather conditions
    
    Parameters: 
        garment_set (set[Garment]): set of all user-owned garments

    Returns: 
        set[Garment]: set of garments filtered by weather suitability
    """
    utils.query_weather_api()

    filtered = {}
    # Select all shoes for given conditions

    filtered[utils.GarmType.SHOES] = {}

    # Select all pants for given conditions
    filtered[utils.GarmType.PANTS] = {}

    # Select all tops for given conditions
    filtered[utils.GarmType.TOP] = {}
    pass


def ranking_stage(filtered_set: Dict[str, Set[Garment]]) -> Set[Garment]:
    """
    Ranks individual Garments based on custom weighted avg.
    
    Parameters: 
        filtered_set (set[Garment]): garments from previous stage

    Returns: 
        set[Garment]: Set of ranked garments
    """
    pass


def matching_stage(ranked_set: Set[Garment]) -> Set[Garment]:
    """
    Forms outfits given the ranked garments.
    
    Parameters: 
        ranked_set (set[Garment]): garments from previous stage

    Returns:
        set[Garment]: List of Garments
    """
    pass
