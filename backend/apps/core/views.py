import json
import time
import base64

from django.http import FileResponse, HttpResponse, HttpResponseBadRequest, JsonResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .decorators import require_method
from .functions import *
from .utils import *
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
    if image.content_type in ['image/png']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")

    filename = f"{username}_{round(time.time()*1000)}.{filetype}"

    image_path = save_image_in_tmp(image, filename)

    # Limit image size to 10MB
    if os.path.isfile(filename) and os.path.getsize(image_path) > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    # Get color
    try:
        red = int(fields["red"])
        green = int(fields["green"])
        blue = int(fields["blue"])
        red_secondary = int(fields["red_secondary"])
        green_secondary = int(fields["green_secondary"])
        blue_secondary = int(fields["blue_secondary"])
        if not (0 <= red <= 255 and
                0 <= red_secondary <= 255 and
                0 <= green <= 255 and
                0 <= green_secondary <=255 and
                0 <= blue <= 255 and
                0 <= blue_secondary <= 255):
            raise ValueError
    except ValueError:
        return HttpResponseBadRequest("Error: the color fields, must be a non-negative integer within the range of [0,255]")

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
        color_lstar_2nd=lstar_secondary,
        color_astar_2nd=astar_secondary,
        color_bstar_2nd=bstar_secondary,
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
    query = Clothing.objects.filter(user=user, is_deleted=False)

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

        (r,g,b) = lab_to_rgb(lab_colors[0])
        item['colors_primary'] = (r,g,b)

        (r,g,b) = lab_to_rgb(lab_colors_2nd[0])
        item['colors_secondary'] = (r,g,b)

    response_data = {'items': clothing_list}
    return JsonResponse(response_data)

@csrf_exempt
@require_method('POST')
def log_outfit(request):
    try:
        # Get username and clothing_ids from form data
        username = request.POST.get('username')
        clothing_ids_str = request.POST.get('clothing_ids')

        if username is None:
            return HttpResponseBadRequest("Required field 'username' not provided. Please try again.")
        if clothing_ids_str is None:
            return HttpResponseBadRequest("Required field 'clothing_ids' not provided. Please try again.")

        # Convert clothing_ids string to list
        clothing_ids = [int(id) for id in clothing_ids_str.split(',')]

        user = get_object_or_404(User, username=username)

        # Validate all clothing items belong to user
        clothing_items = []
        for clothing_id in clothing_ids:
            clothing_item = get_object_or_404(Clothing, id=clothing_id, user=user)
            clothing_items.append(clothing_item)

        # Create outfit
        outfit = Outfit(date_worn=timezone.now())

        # Handle image upload if present
        if 'image' in request.FILES:
            image = request.FILES['image']

            # Validate filetype
            if image.content_type not in ['image/png', 'image/jpeg']:
                return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")

            filetype = image.content_type[6:]
            filename = f"outfit/{username}_{round(time.time()*1000)}.{filetype}"

            # Upload directly to R2
            try:
                r2.upload_fileobj(image, IMAGE_BUCKET, filename)
                outfit.img_filename = filename
            except Exception as e:
                return HttpResponseBadRequest(f"Failed to upload image to R2: {str(e)}")

        outfit.save()

        # Create outfit items
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

    # Compress image and remove background
    img = Image.open(image_path)

    img = compress_image(img)
    img = img_bg_rm(img)

    img.save(image_path)
    img.close()

    color_palette = extract_palette(image_path)[:2]

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

        # Todo: Implement soft delete given the list of ids
        for cur_id in ids:
            clothing_item = Clothing.objects.get(id=cur_id)
            clothing_item.is_deleted = True;
            clothing_item.save()

        return HttpResponse(status=200)
    except:
        return HttpResponseBadRequest(f"Required field 'ids' not provided. Please try again.\n")

@csrf_exempt
@require_method('GET')
def get_feed(request):
    # Get pagination parameters
    cursor = request.GET.get('cursor')
    page_size = int(request.GET.get('page_size', 10))

    # Base query starting from OutfitItem
    outfit_items_query = OutfitItem.objects.select_related(
        'outfit',
        'clothing',
        'clothing__user'
    ).prefetch_related(
        'clothing__tags_set'
    ).filter(
        outfit__img_filename__isnull=False
    ).order_by('-outfit__date_worn')

    # Apply cursor if provided
    if cursor:
        try:
            cursor_date = timezone.datetime.fromisoformat(cursor)
            outfit_items_query = outfit_items_query.filter(outfit__date_worn__lt=cursor_date)
        except ValueError:
            return HttpResponseBadRequest("Invalid cursor format. Use ISO 8601 datetime format.")

    # Get outfit items and group by outfit
    outfit_items = outfit_items_query[:page_size * 10]  # Get enough items to fill page_size outfits

    # Group by outfit and format response
    feed_items = []
    current_outfit = None
    current_clothing_items = []

    for item in outfit_items:
        if current_outfit is None:
            current_outfit = item.outfit
            current_clothing_items = []

        if item.outfit.id != current_outfit.id:
            # Save previous outfit
            feed_items.append({
                'id': current_outfit.id,
                'img_filename': current_outfit.img_filename,
                'date_worn': current_outfit.date_worn.isoformat(),
                'username': current_outfit.outfititem_set.first().clothing.user.username,
                'clothing_items': current_clothing_items
            })

            # Start new outfit
            current_outfit = item.outfit
            current_clothing_items = []

            # Check if we've reached page_size
            if len(feed_items) >= page_size:
                break

        # Add clothing item with all fields
        clothing = item.clothing
        current_clothing_items.append({
            'id': clothing.id,
            'type': clothing.type,
            'subtype': clothing.subtype,
            'img_filename': clothing.img_filename,
            'color_lstar': clothing.color_lstar,
            'color_astar': clothing.color_astar,
            'color_bstar': clothing.color_bstar,
            'fit': clothing.fit,
            'layerable': clothing.layerable,
            'precip': clothing.precip,
            'occasion': clothing.occasion,
            'weather': clothing.weather,
            'created_at': clothing.created_at.isoformat(),
            'tags': [{'label': tag.label, 'value': tag.value} for tag in clothing.tags_set.all()]
        })

    # Add last outfit if exists
    if current_outfit and len(feed_items) < page_size:
        feed_items.append({
            'id': current_outfit.id,
            'img_filename': current_outfit.img_filename,
            'date_worn': current_outfit.date_worn.isoformat(),
            'username': current_outfit.outfititem_set.first().clothing.user.username,
            'clothing_items': current_clothing_items
        })

    # Get next cursor from the last item
    next_cursor = None
    if len(outfit_items) >= page_size * 10:  # If we got the maximum number of items
        next_cursor = feed_items[-1]['date_worn'] if feed_items else None

    return JsonResponse({
        'outfits': feed_items,
        'next_cursor': next_cursor
    })
