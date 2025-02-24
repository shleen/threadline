from django.core.exceptions import ObjectDoesNotExist

from .models import User


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
