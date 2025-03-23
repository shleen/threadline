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

    if "username" in fields:
        username = fields["username"]
    else:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    if "type" in fields:
        clothing_type = fields["type"]
    else:
        return HttpResponseBadRequest("Required field 'type' not provided. Please try again.")

    subtype = None
    if "subtype" in fields:
        subtype = fields["subtype"]

    fit = "LOOSE"
    # if "fit" in fields:
    #     fit = fields["fit"]
    # else:
    #     return HttpResponseBadRequest("Required field 'fit' not provided. Please try again.")

    layerable = False
    if "layerable" in fields:
        layerable = fields["layerable"]

    precip = None
    if "precip" in fields:
        precip = fields["precip"]

    occasion = "FORMAL"
    # if "occasion" in fields:
    #     occasion = fields["occasion"]
    # else:
    #     return HttpResponseBadRequest("Required field 'occasion' not provided. Please try again.")

    winter = False
    # if "winter" in fields:
    #     winter = fields["winter"]
    #     if winter != "True" and winter != "False":
    #         return HttpResponseBadRequest("The Value of the field 'winter' must be 'True' or 'False'")
    # else:
    #     return HttpResponseBadRequest("Required field 'winter' not provided. Please try again.")

    image = None
    for _, file in request.FILES.items():
        image = file

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    # TODO: process tags
    # tags is optional
    if "tags" in fields:
        for tag in fields["tags"]:
            pass

    ## Process & upload image to Cloudflare R2
    # Validate filetype
    if image.content_type in ['image/png', 'image/jpeg']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")

    # Compress image
    compress_image(image_path)

    # Limit image size to 10MB
    if image.size > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    filename = f"{username}_{round(time.time()*1000)}.{filetype}"

    image_path = save_image_in_tmp(image, filename)

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
            break;
        except:
            if attempt >= 4:
                return HttpResponseBadRequest("Database Insertion Failure.")

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
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    # Weather Filtering API Call Here
    lat = request.GET.get('lat')
    lon = request.GET.get('lon')

    # Use defaults for is_winter and precip
    is_winter = False
    precip = None

    if lat and lon:
        # Get weather at location
        weather = get_weather(float(lat), float(lon))

        is_winter = weather["temp"] < 45
        precip = weather["precip"]
    else:
        # TODO: decide how to handle this. FE error?
        pass

    context = { "username": username, "iswinter": is_winter, "precip": precip }
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
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    image = request.GET.get('image')

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    if image.content_type in ['image/png', 'image/jpeg']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")


    # Save Image to tempdir,
    filename = f"{username}_{round(time.time()*1000)}.{filetype}"
    image_path = save_image_in_tmp(image, filename)

    # convert to PNG if file is JPEG
    if image.content_type is 'image/jpeg':
        filename = f"{username}_{round(time.time()*1000)}.png"
        with Image.open(image_path) as img:
            img.save(image_path, 'PNG')

    #remove image background
    img_bg_rm(image_path)

    bg_free_image_file = open(image_path, 'rb')
    return FileResponse(bg_free_image_file, content_type='image/png')

