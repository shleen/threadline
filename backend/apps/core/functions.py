from django.core.cache import cache
from django.core.exceptions import ObjectDoesNotExist
from django.core.files.uploadedfile import UploadedFile

from .models import User
from .queries import *
from PIL import Image
from rembg import remove
from colorthief import ColorThief
import os
import requests
import tempfile
import time


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
        outfit = {k: None for k in ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]}

        for k, queue in ranked.items():
            if k == "DRESS" or k == "OUTERWEAR":
                continue
            garment = queue.pop()

            if outfit[k] is None:
                outfit[k] = [{"id": garment["id"], "img": garment["img_filename"]}]
            else:
                outfit[k].append({"id": garment["id"], "img": garment["img_filename"]})

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

        garment = {"clothing_id": rec["clothing_id"], "img": rec["img_filename"]}
        if outfit[rec["type"]] is None:
            outfit[rec["type"]] = [garment]
        else:
            outfit[rec["type"]].append(garment)

        outfit_dict[outfit_id] = outfit

    return sorted(list(outfit_dict.values()), key=lambda outfit: outfit["timestamp"], reverse=True)[:15]



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
            precip = "RAIN"
        elif 600 <= weather_id <= 699:
            precip = "SNOW"

        result = {
            "temp": temp,
            "precip": precip,
            "location": f"{lat}, {lon}",
        }

        # update the cache with current timestamp and result data
        cache.set(key, {"timestamp": now, "data": result})
        return result
    else:
        raise Exception("failed to fetch weather data")

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
