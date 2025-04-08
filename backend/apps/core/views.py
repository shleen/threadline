import json
import time
import base64

from django.http import FileResponse, HttpResponse, HttpResponseBadRequest, JsonResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .decorators import require_method
from .functions import *
from .images import IMAGE_BUCKET, r2
from .models import Clothing, User, Tags, Outfit, OutfitItem

from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
@require_method('POST')
def create_clothing(request):
    ## Validate and extract request fields
    fields = request.POST

    # Required fields
    required_fields = ["username", "type", "fit", "occasion", "winter", "red", "red_secondary", "green", "green_secondary", "blue", "blue_secondary"]
    for field in required_fields:
        if field not in fields:
            return HttpResponseBadRequest(f"Required field '{field}' not provided. Please try again.")

    username = fields["username"]
    clothing_type = fields["type"]
    fit = fields["fit"]
    occasion = fields["occasion"]
    winter = fields["winter"]

    if winter not in ["True", "False"]:
        return HttpResponseBadRequest("The value of the field 'winter' must be 'True' or 'False'")
    winter = winter == "True"

    # Optional fields
    subtype = fields.get("subtype", None)
    layerable = fields.get("layerable", "False") == "True"
    precip = fields.get("precip", None)

    # Process tags
    tags = []
    if "tags" in fields:
        tags_string = fields["tags"]
        tags = tags_string.split(',')

    # Process image
    image = None
    for _, file in request.FILES.items():
        image = file

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    # Validate filetype
    if image.content_type in ['image/png', 'image/jpeg']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")

    filename = f"{username}_{round(time.time()*1000)}.{filetype}"

    image_path = save_image_in_tmp(image, filename)

    # Limit image size to 10MB
    if os.path.isfile(filename) and os.path.getsize(image_path) > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    # TODO: Get color
    try:
        red = int(fields["red"])
        green = int(fields["green"])
        blue = int(fields["blue"])
        red_secondary = int(fields["red_secondary"])
        green_secondary = int(fields["green_secondary"])
        blue_secondary = int(fields["blue_secondary"])
        if red < 0 or red_secondary < 0 or green < 0 or green_secondary < 0 or blue < 0 or blue_secondary < 0:
            raise ValueError
    except ValueError:
        return HttpResponseBadRequest("Error: the color fields (red, green, blue), must be a non-negative integer")

    (lstar_primary, astar_primary, bstar_primary) = rgb_to_lab((red, green, blue))
    (lstar_secondary, astar_secondary, bstar_secondary) = rgb_to_lab((red_secondary, green_secondary, blue_secondary))

    ## Insert clothing item to DB
    user = get_or_create_user(username)
    item = Clothing(
        type=clothing_type,
        subtype=subtype,
        img_filename=filename,
        color_lstar=lstar_primary,
        color_astar=astar_primary,
        color_bstar=bstar_primary,
        color_lstar_2nd=lstar_primary,
        color_astar_2nd=astar_primary,
        color_bstar_2nd=bstar_primary,
        fit=fit,
        layerable=layerable,
        precip=precip,
        occasion=occasion,
        weather=Clothing.Weather.WINTER if winter else Clothing.Weather.SUMMER,
        user=user
    )

    # Insert into database, upload to R2, and retry if error
    for attempt in range(5):
        try:
            item.save()
            break
        except:
            if attempt >= 4:
                return HttpResponseBadRequest("Database Insertion Failure.")

    # Save tags to the database
    for tag in tags:
        try:
            tag_obj = Tags(value=tag, clothing=item, user=user)
            tag_obj.save()
        except ValueError:
            return HttpResponseBadRequest("Invalid tag format. Tags should be in 'label:value' format.")

    for attempt in range(5):
        try:
            # r2.upload_fileobj(image, IMAGE_BUCKET, filename)
            r2.upload_file(image_path, IMAGE_BUCKET, filename)
            return HttpResponse(status=200)
        except:
            if attempt >= 4:
                item.delete()
                return HttpResponseBadRequest("R2 Upload Failure.")

def get_closet(request):
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    user = get_object_or_404(User, username=username)
    # Start with base query and evaluate it once
    query = Clothing.objects.filter(user=user)

    type = request.GET.get('type')
    if type is not None:
        query = query.filter(type=type)

    # Get all clothing items and include their tags
    clothing_list = list(query.values(
        'id',
        'type',
        'subtype',
        'img_filename',
        'fit',
        'layerable',
        'precip',
        'occasion',
        'weather',
        'created_at'
    ))

    for item in clothing_list:
        # Add tags to each item
        item['tags'] = list(Tags.objects.filter(clothing_id=item['id']).values('label', 'value'))
        # Add RGB Values converted from CIELAB
        lab_colors = Clothing.objects.filter(id=item['id']).values_list('color_lstar', 'color_astar', 'color_bstar')
        lab_colors_2nd = Clothing.objects.filter(id=item['id']).values_list('color_lstar_2nd', 'color_astar_2nd', 'color_bstar_2nd')
        rgb_colors = list()
        rgb_colors_2nd = list()

        for color in lab_colors:
            (r,g,b) = lab_to_rgb(color)
            rgb_colors.append((r,g,b))
        item['colors_primary'] = rgb_colors

        for color_2nd in lab_colors_2nd:
            (r,g,b) = lab_to_rgb(color_2nd)
            rgb_colors_2nd.append((r,g,b))
        item['colors_secondary'] = rgb_colors_2nd

    response_data = {'items': clothing_list}
    return JsonResponse(response_data)

@csrf_exempt
@require_method('POST')
def log_outfit(request):
    try:
        fields = json.loads(request.body.decode('utf-8'))
        username = fields.get('username')
        clothing_ids = fields.get('clothing_ids')

        if username is None:
            return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")
        if clothing_ids is None:
            return HttpResponseBadRequest("Required field 'clothing_ids' not provided. Please try again.")

        user = get_object_or_404(User, username=username)

        # Validate all clothing items belong to user
        clothing_items = []
        for clothing_id in clothing_ids:
            clothing_item = get_object_or_404(Clothing, id=clothing_id, user=user)
            clothing_items.append(clothing_item)

        # Create outfit and save outfit items
        outfit = Outfit(date_worn=timezone.now())
        outfit.save()

        for clothing_item in clothing_items:
            outfit_item = OutfitItem(clothing=clothing_item, outfit=outfit)
            outfit_item.save()

        return HttpResponse(status=200)
    except Exception as e:
        return HttpResponseBadRequest(f"An error occurred: {str(e)}")

@csrf_exempt
@require_method('GET')
def get_recommendations(request):
    # Validate URL Params
    username = request.GET.get('username')
    lat = request.GET.get('lat')
    lon = request.GET.get('lon')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    if not (lat and lon):
        return HttpResponseBadRequest("No latitude or longitude provided")

    # Get weather at location
    conditions = get_weather(float(lat), float(lon))

    context = {
        "username": username,
        "weather": conditions["weather"],
        "precip": conditions["precip"]
    }
    clothes = filter_and_rank(context)
    matched = item_match(clothes)

    return JsonResponse({
        "outfits": matched
    })

@csrf_exempt
@require_method('GET')
def get_prev_outfits(request):
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    return JsonResponse({
        "outfits": pull_past_outfits({ "username": username })
    })

@csrf_exempt
@require_method('GET')
def get_utilization(request):
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    return JsonResponse({
        "utilization": compute_utilization({ "username": username }),
        "rewears": compute_rewears({ "username": username })
    })

# Returns image in base64 encoded data, with its background removed
@csrf_exempt
@require_method('POST')
def remove_background(request):
    username = request.POST.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    for _, file in request.FILES.items():
        image = file

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    if image.content_type in ['image/png']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png). Please try again.")


    # Save Image to tempdir,
    filename = f"{username}_{round(time.time()*1000)}.{filetype}"
    image_path = save_image_in_tmp(image, filename)

    #remove image background
    img_bg_rm(image_path)

    bg_free_image_file = open(image_path, 'rb')
    return FileResponse(bg_free_image_file, content_type='image/png')

@csrf_exempt
@require_method('POST')
def process_image(request):
    username = request.POST.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    for _, file in request.FILES.items():
        image = file

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    if image.content_type in ['image/png']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png). Please try again.")

    # Save Image to tempdir,
    filename = f"{username}_{round(time.time()*1000)}.{filetype}"
    image_path = save_image_in_tmp(image, filename)

    #remove image background
    img_bg_rm(image_path)

    color_palette = extract_palette(image_path)[:2]

    # Compress image
    compress_image(image_path)

    # json_data = json.dumps([{"r": r, "g": g, "b": b} for r, g, b in color_palette], indent=2)
    json_data = json.dumps(color_palette)

    # Sadly, Django does not support multipart HTTP Response
    # Open image as base64 encoded string
    with open(image_path, "rb") as img_file:
        encoded_string = base64.b64encode(img_file.read()).decode('utf-8')

    return JsonResponse({
        "colors": json_data,
        "image_base64": f"{encoded_string}"
    })

@csrf_exempt
@require_method('GET')
def get_categories(_):
    return JsonResponse(pull_clothing_tags())

@csrf_exempt
@require_method('GET')
def get_declutter(request):
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    return JsonResponse({
        "declutter": pull_declutter({"username": username})
    })

@csrf_exempt
@require_method('POST')
def post_declutter(request):
    ## Validate and extract request fields
    fields = json.loads(request.body.decode('utf-8'))
    try:
        ids = fields["ids"]
        print(ids)

        # Todo: Implement soft delete given the list of ids
        return HttpResponse(status=200)
    except:
        return HttpResponseBadRequest(f"Required field 'ids' not provided. Please try again.\n")
