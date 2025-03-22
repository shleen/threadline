import time

from django.http import HttpResponse, HttpResponseBadRequest, JsonResponse
from django.shortcuts import get_object_or_404

from .decorators import require_method
from .functions import *
from .images import IMAGE_BUCKET, r2
from .models import Clothing, User, Tags

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

    if "fit" in fields:
        fit = fields["fit"]
    else:
        return HttpResponseBadRequest("Required field 'fit' not provided. Please try again.")

    layerable = False
    if "layerable" in fields:
        layerable = fields["layerable"]

    precip = None
    if "precip" in fields:
        precip = fields["precip"]

    if "occasion" in fields:
        occasion = fields["occasion"]
    else:
        return HttpResponseBadRequest("Required field 'occasion' not provided. Please try again.")

    if "winter" in fields:
        winter = fields["winter"]
    else:
        return HttpResponseBadRequest("Required field 'winter' not provided. Please try again.")

    image = None
    for _, file in request.FILES.items():
        image = file

    if image is None:
        return HttpResponseBadRequest("Required field 'image' not provided. Please try again.")

    # TODO: process tags
    # tags is optional
    if "tags" in fields:
        for tag in fileds:
            pass

    ## Process & upload image to Cloudflare R2
    # Validate filetype
    if image.content_type in ['image/png', 'image/jpeg']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")


    # Limit image size to 10MB
    if image.size > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    # TODO: Get color
    color_lstar = 0.0
    color_astar = 0.0
    color_bstar = 0.0

    filename = f"{username}_{round(time.time()*1000)}.{filetype}"

    # Compress image
    image:UploadedFile = compress_image(image)

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
            if attempt >= 5:
                return HttpResponseBadRequest("Database Insertion Failure.")

    for attempt in range(5):
        try:
            r2.upload_fileobj(image, IMAGE_BUCKET, filename)
            return HttpResponse(status=200)
        except:
            if attempt >= 5:
                item.delete()
                return HttpResponseBadRequest("R2 Upload Failure.")


def get_closet(request):
    username = request.GET.get('username')

    if username is None:
        return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")

    user = get_object_or_404(User, username=username)

    # Get Clothing type we want to filter with if one is provided
    type = request.GET.get('type')


    # Get all clothing items and include their tags
    clothes_query = Clothing.objects.filter(user=user)

    # Apply second filter if type is specified
    if type is not None:
        clothes_query = clothes_query.filter(type=type)

    clothes = clothes_query.values(
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
    )


    for item in clothes:
        item['tags'] = list(Tags.objects.filter(clothing_id=item['id']).values('label', 'value'))

    return JsonResponse({
        'items': list(clothes)
    })

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
