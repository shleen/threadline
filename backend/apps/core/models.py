from django.db import models
from django.utils import timezone

class User(models.Model):
    username = models.CharField(unique=True)


class Clothing(models.Model):
    class ClothingType(models.TextChoices):
        SHIRT = "SHIRT"
        JACKET = "JACKET"
        COAT = "COAT"
        PANTS = "PANTS"
        SHORTS = "SHORTS"
        SHOES = "SHOES"

    class Precip(models.TextChoices):
        RAIN = "RAIN"
        SNOW = "SNOW"

    class Occasion(models.TextChoices):
        ACTIVE = "ACTIVE"
        CASUAL = "CASUAL"
        BUSINESS = "BUSINESS"

    class Season(models.TextChoices):
        WINTER = "WINTER"
        SPRING = "SPRING"
        SUMMER = "SUMMER"
        FALL = "FALL"


    type = models.CharField(choices=ClothingType)

    img_url = models.URLField()

    # CIELAB color space color
    color_lstar = models.FloatField()
    color_astar = models.FloatField()
    color_bstar = models.FloatField()

    # if true, this item can be worn on top of other items
    layerable = models.BooleanField(default=False)

    precip = models.CharField(choices=Precip, blank=True)

    occasion = models.CharField(choices=Occasion)

    season = models.CharField(choices=Season)

    created_at = models.DateTimeField(default=timezone.now)

    user_id = models.ForeignKey(User, on_delete=models.CASCADE)


class Tags(models.Model):
    label = models.CharField(blank=True)
    value = models.CharField()

    clothing_id = models.ForeignKey(Clothing, on_delete=models.CASCADE)

    user_id = models.ForeignKey(User, on_delete=models.CASCADE)
