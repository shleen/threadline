import boto3
import time

from django.http import HttpResponse, HttpResponseBadRequest

from .decorators import require_method
from .functions import get_or_create_user
from .models import Clothing

IMAGE_BUCKET = "threadline-clothing"

# first param here is because boto3 was built for use with AWS S3,
# and Cloudflare R2 is compatible with many AWS S3 SDKs
r2 = boto3.client('s3',
  endpoint_url='https://7b0edb7ebfca88e47f0f02147ca9274e.r2.cloudflarestorage.com',
  region_name='enam'
)

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
        pass

    ## Process & upload image to Cloudflare R2
    # Validate filetype
    if image.content_type in ['image/png', 'image/jpeg']:
        filetype = image.content_type[6:]
    else:
        return HttpResponseBadRequest("Provided 'image' is not of an acceptable image type (png, jpeg). Please try again.")

    # TODO: Compress image

    # Limit image size to 10MB
    if image.size > 10**6:
        return HttpResponseBadRequest("Provided 'image' is larger than the 10MB limit. Please try again.")

    # TODO: Get color
    color_lstar = 0.0
    color_astar = 0.0
    color_bstar = 0.0

    # TODO: Remove image background

    filename = f"{username}_{round(time.time()*1000)}.{filetype}"
    r2.upload_fileobj(image, IMAGE_BUCKET, filename)

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
    item.save()

    return HttpResponse(status=200)
