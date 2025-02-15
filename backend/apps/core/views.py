from django.http import HttpResponse

from .decorators import require_method

@require_method('POST')
def create_clothing(request):
    # TODO: validate fields
    # TODO: insert clothing item

    return HttpResponse(status=200)
