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
    required_fields = ["username", "type", "fit", "occasion", "winter"]
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

    # Compress image
    compress_image(image_path)

    # Limit image size to 10MB
    if os.path.isfile(filename) and os.path.getsize(image_path) > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    # TODO: Get color
    color_lstar = 0.0
    color_astar = 0.0
    color_bstar = 0.0

    ## Insert clothing item to DB
    user = get_or_create_user(username)
    item = Clothing(
        type=clothing_type,
        subtype=subtype,
        img_filename=filename,
        color_lstar=color_lstar,
        color_astar=color_astar,
        color_bstar=color_bstar,
        fit=fit,
        layerable=layerable,
        precip=precip,
        occasion=occasion,
        winter=winter,
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
            tag_label, tag_value = tag.split(':')
            tag_obj = Tags(label=tag_label, value=tag_value, clothing=item, user=user)
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
        'color_lstar',
        'color_astar',
        'color_bstar',
        'fit',
        'layerable',
        'precip',
        'occasion',
        'winter',
        'created_at'
    ))
    # Add tags to each item
    for item in clothing_list:
        item['tags'] = list(Tags.objects.filter(clothing_id=item['id']).values('label', 'value'))

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
@require_method('GET')
def get_categories(_):
    return JsonResponse(pull_clothing_tags())
