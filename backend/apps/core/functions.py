from django.core.exceptions import ObjectDoesNotExist

from .models import User
from .queries import *


def get_or_create_user(username):
    """
    Returns a user object with a matching username from the database.
    If the given username does not exist, create a new user and return. 
    """
    try:
        user = User.objects.get(username=username)
    except ObjectDoesNotExist:
        user = User(username=username)
        user.save()
    
    return user


def filter_and_rank(context):
    """
    Raw SQL query to perform weather filtering and garment ranking
    entirely on the database. Returns the top items for each type of 
    garment. Context includes the username and parameters computed for 
    weather filtering from the API call.
    """
    records = execute_read_query(ranking_query(context), [context["username"]])

    # Group garments into queues based on their type
    ranked_queues = {k: [] for k in ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]}
    for rec in records:
        ranked_queues[rec["type"]].append(rec)

    return ranked_queues

def item_match(ranked):
    """
    Matches clothes from ranking stage to form outfits. The full 
    implementation is an MVP feature so for skeletal it is minimial
    and will just create up to 5 outfits of top, bottom, and shoes.
    """
    if len(ranked.keys()) == 0:
        return []

    outfits = []
    while len(ranked["TOP"]) > 0 and len(ranked["BOTTOM"]) > 0 and len(ranked["SHOES"]) > 0:
        outfit = {}
        for k, queue in ranked.items():
            if k == "DRESS" or k == "OUTERWEAR":
                outfit[k] = None
                continue
            garment = queue.pop()
            outfit[k] = {"id": garment["id"], "img": garment["img_filename"]}

        outfits.append(outfit)

    return outfits


def pull_past_outfits(context):
    """
    Fetches up to 15 previously worn outfits along with their dates worn. 
    Returns the results in decescending order by most recently worn.
    """
    records = execute_read_query(prev_outfit_query(), [context["username"]])
    
    # Flatten records into outfits
    outfit_dict = {}
    for rec in records:
        outfit_id = rec["outfit_id"]
        outfit = outfit_dict.get(outfit_id, 
            {k: None for k in ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]})
        
        outfit["outfit_id"] = outfit_id
        outfit["timestamp"] = rec["date_worn"]
        outfit[rec["type"]] = {"clothing_id": rec["clothing_id"], "img": rec["img_filename"]}
        outfit_dict[outfit_id] = outfit

    return sorted(list(outfit_dict.values()), key=lambda outfit: outfit["timestamp"], reverse=True)


def compute_utilization(context):
    """
    Computes total wardrobe utilization and utilization percentage for
    each type of clothing that has been worn within the past month
    """
    utilization = execute_read_query(utilization_query(), [context["username"]])

    util_dict = {k: None for k in ["TOTAL", "TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]}
    
    # Map returned percentages to utilization dictionary
    for util in utilization:
        util_dict[util["util_type"]] = util["percent"]

    return util_dict


def compute_rewears(context):
    """
    Pull which items of clothing were reworn (i.e., worn more than once)
    the most in the last month
    """
    rewears = execute_read_query(rewears_query(), [context["username"]])

    # For each type that has rewears, build a list of clothing item JSONs
    rewear_dict = {k: None for k in ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]}
    for rewear in rewears:
        key = rewear["type"]
        rewear.pop("type")

        if rewear_dict[key] is None:
           rewear_dict[key] = [rewear]
           continue

        rewear_dict[key].append(rewear) 
        
    return rewear_dict
