from django.core.cache import cache
from django.core.exceptions import ObjectDoesNotExist
from django.core.files.uploadedfile import UploadedFile

from .models import *
from .queries import *
from .utils import *

from PIL import Image
from rembg import remove
from colorthief import ColorThief
from itertools import groupby
import os
import requests
import tempfile
import time
import random


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

def pull_clothing_tags():
    """
    Returns all categories for tags on the fronted
    """
    return {
        "type": BASE_TYPES,
        "occasion": BASE_OCCASIONS,
        "fit": BASE_FIT,
        "precip": BASE_PRECIP,
        "subtype": BASE_SUBTYPE,
        "weather": BASE_WEATHER
    }


def filter_and_rank(context):
    """
    Raw SQL query to perform weather filtering and garment ranking
    entirely on the database. Returns the top items for each type of
    garment. Context includes the username and parameters computed for
    weather filtering from the API call.
    """
    context["clothing_types"] = BASE_TYPES
    records = execute_read_query(ranking_query(context), [context["username"]])

    # Group garments into queues based on their type
    ranked_queues = {k: [] for k in BASE_TYPES}
    for rec in records:
        ranked_queues[rec["type"]].append(rec)

    return ranked_queues


def get_target_colors(color):
    """
    Get complementary and analogous colors for a given CIELAB color.

    Args:
        color: Tuple of (L*, a*, b*) values in CIELAB color space

    Returns:
        List of 3 CIELAB colors: [complementary, analogous1, analogous2]
    """
    l, a, b = color

    # Convert to HCL
    h, c, l = lab_to_hcl(l, a, b)

    # Calculate target hues
    h_complement = (h + 180) % 360  # Complementary color (opposite on wheel)
    h_analogous1 = (h + 30) % 360   # First analogous (30 degrees clockwise)
    h_analogous2 = (h - 30) % 360   # Second analogous (30 degrees counter-clockwise)

    # Convert back to LAB
    complement = hcl_to_lab(h_complement, c, l)
    analogous1 = hcl_to_lab(h_analogous1, c, l)
    analogous2 = hcl_to_lab(h_analogous2, c, l)

    return [complement, analogous1, analogous2]

def color_distance(color1, color2):
    """
    Calculate the Euclidean distance between two colors in CIELAB space.

    Args:
        color1: Tuple of (L*, a*, b*) values for the first color
        color2: Tuple of (L*, a*, b*) values for the second color

    Returns:
        float: The distance between the two colors
    """
    return math.sqrt(sum((c1 - c2) ** 2 for c1, c2 in zip(color1, color2))) #each pair of colors, find the squared diff and sum them

def color_match(clothes,target_colors):
    """
    Find the clothes that best matches the target colors
    """ 
    if not clothes:
        return None

    best_item = None
    best_distance = float("inf")
    for item in clothes:
        item_color = (item["color_lstar"], item["color_astar"], item["color_bstar"])

        min_distance = min(color_distance(item_color, target_color) for target_color in target_colors)
        if min_distance < best_distance:    
            best_distance = min_distance
            best_item = item

    return best_item


def item_match(ranked):
    """
    Matches clothes from ranking stage to form outfits. The full
    implementation is an MVP feature so for skeletal it is minimial
    and will just create up to 5 outfits of top, bottom, and shoes.
    """
    outfits = []
    for i in range(5):
        outfit = []
        if (len(ranked[Clothing.ClothingType.DRESS]) > 0 and random.randint(0,1)):
            dress = ranked[Clothing.ClothingType.DRESS].pop()
            outfit.append({"id": dress["id"], "img": dress["img_filename"], "type": Clothing.ClothingType.DRESS})
            target_colors = get_target_colors((dress["color_lstar"], dress["color_astar"], dress["color_bstar"]))

            for k in ranked.keys():
                if k not in [Clothing.ClothingType.DRESS, Clothing.ClothingType.TOP,Clothing.ClothingType.BOTTOM]:
                    best_item = color_match(ranked[k], target_colors)
                    outfit.append({"id": best_item["id"], "img": best_item["img_filename"], "type": k})
                
            outfits.append({"clothes": outfit})

        elif len(ranked[Clothing.ClothingType.TOP]) > 0:
            top = ranked[Clothing.ClothingType.TOP].pop()
            outfit.append({"id": top["id"], "img": top["img_filename"], "type": Clothing.ClothingType.TOP})
            target_colors = get_target_colors((top["color_lstar"], top["color_astar"], top["color_bstar"]))

            for k in ranked.keys():
                if k not in [Clothing.ClothingType.DRESS, Clothing.ClothingType.TOP]:
                    best_item = color_match(ranked[k], target_colors)
                    outfit.append({"id": best_item["id"], "img": best_item["img_filename"], "type": k})
                
            outfits.append({"clothes": outfit})
    
    return outfits


def pull_past_outfits(context):
    """
    Fetches up to 15 previously worn outfits along with their dates worn.
    Returns the results in decescending order by most recently worn.
    """
    records = execute_read_query(prev_outfit_query(), [context["username"]])

    # Flatten records into outfits
    return sorted([
        {
            "outfit_id": outfit_id,
            "timestamp": timestamp,
            "clothes": [
                {
                    "clothing_id": cloth["clothing_id"],
                    "img": cloth["img_filename"]
                }
                for cloth in group
            ]
        }
        for (outfit_id, timestamp),  group in groupby(
            records, lambda cloth: (cloth["outfit_id"], cloth["date_worn"]))
    ], key=lambda outfit: outfit["timestamp"], reverse=True)



def compute_utilization(context):
    """
    Computes total wardrobe utilization and utilization percentage for
    each type of clothing that has been worn within the past month
    """
    utilization = execute_read_query(utilization_query(), [context["username"]])
    util_types = list(filter(lambda util: util["util_type"] != "TOTAL", utilization))


    return {
        "TOTAL": [float(util["percent"]) for util in utilization if util["util_type"] == "TOTAL"][0],
        "utilization":  list(map(lambda ut: {"util_type": ut["util_type"], "percent": float(ut["percent"])}, util_types))
    }

def compute_rewears(context):
    """
    Pull which items of clothing were reworn (i.e., worn more than once)
    the most in the last month
    """
    context["clothing_types"] = BASE_TYPES
    return execute_read_query(rewears_query(context), [context["username"]])


def compress_image(img_path, quality=70):
    img = Image.open(img_path)
    img.save(img_path, optimize=True, quality=quality)
    img.close()

# Returns file_path of the image in /tmp
def save_image_in_tmp(image: UploadedFile, filename):
    temp_dir = tempfile.mkdtemp()
    file_path = os.path.join(temp_dir, filename)

    # Save file
    with open(file_path, 'wb') as img_file:
        for chunk in image.chunks():
            img_file.write(chunk)

    return file_path

# Overwrites image file with a version with the background removed
def img_bg_rm(file_path):
    input = Image.open(file_path)
    output = remove(input)
    output.save(file_path)

# Expects path to a png image with background removed
# Returns List of tuples representing RGB values
def extract_palette(file_path, num_colors=2):
    color_thief = ColorThief(file_path)
    return color_thief.get_palette(color_count=num_colors, quality=1)

def get_weather(lat, lon):
    """
    Checks cache to see for weather info for this location. Sameness of location is determined
    if the coordinates (round(lat, 1), round(lon, 1)) exist in the cache. If the cached data is
    still valid (made less than 6 hours ago), return that. If not, remove it from the cache and
    make a call to the API as below, and update the cache.

    If no matches are found in the cache, makes a HTTP request to the OpenWeatherMap Weather
    endpoint to get the current weather at the provided coordinates. The result of this called
    is cached in memory to limit calls to the API.

    Returns the current weather at (lat, lon) as a dict:
    {
        temp: float,
        precip: string, # Either None, "RAIN", or "SNOW"
        location: string,
    }
    """


    # cache key: 'weater,<latitude rounded to 1dp>,<longitude rounded to 1dp>'
    key = f"weather,{round(lat, 1)},{round(lon, 1)}"
    now = time.time()

    # check if weather data exists in cache and is still valid (< 6 hours old)
    cached = cache.get(key)
    if cached:
        if now - cached["timestamp"] < 6 * 3600:
            return cached["data"]
        else:
            cache.delete(key)

    # build API request URL
    API_KEY = os.getenv("OPENWEATHERMAP_API_KEY")
    url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_KEY}&units=imperial"

    # make the HTTP request to the API
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()

        temp = data["main"]["temp"]

        precip = None
        # See https://openweathermap.org/weather-conditions to make sense of the values below
        weather_id = data["weather"][0]["id"]
        if 200 <= weather_id <= 599:
            precip = Clothing.Precip.RAIN
        elif 600 <= weather_id <= 699:
            precip = Clothing.Precip.SNOW

        # If More seasons/conditions added, add more match arms
        weather = None
        match temp:
            case temp if temp < 45:
                weather = Clothing.Weather.WINTER
            case _:
                weather = Clothing.Weather.SUMMER

        result = {
            "weather": weather,
            "precip": precip,
            "location": f"{lat}, {lon}",
        }

        # update the cache with current timestamp and result data
        cache.set(key, {"timestamp": now, "data": result})
        return result
    else:
        raise Exception("failed to fetch weather data")


def pull_declutter(context):
    """
    Pulls recommended items to declutter
    """
    return execute_read_query(declutter_query(), [context["username"]])
