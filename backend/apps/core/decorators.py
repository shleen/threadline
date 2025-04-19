from django.http import HttpResponse

def require_method(method):
    def decorator(func):
        def wrapper(request, *args, **kwargs):
            if request.method.upper() != method.upper():
                return HttpResponse(status=405)

            return func(request, *args, **kwargs)

        return wrapper

    return decorator
