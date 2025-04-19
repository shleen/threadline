from django.core.exceptions import ValidationError
from django.db import models
from django.db.models.signals import post_delete
from django.dispatch import receiver
from django.utils import timezone

from .images import IMAGE_BUCKET, r2

class User(models.Model):
    username = models.CharField(unique=True)


class Clothing(models.Model):
    class ClothingType(models.TextChoices):
        TOP = "TOP"
        BOTTOM = "BOTTOM"
        OUTERWEAR = "OUTERWEAR"
        DRESS = "DRESS"
        SHOES = "SHOES"

    class TopSubtype(models.TextChoices):
        ACTIVE = "ACTIVE"
        T_SHIRT = "T-SHIRT"
        POLO = "POLO"
        BUTTON_DOWN = "BUTTON DOWN"
        HOODIE = "HOODIE"
        SWEATER = "SWEATER"

    class BottomSubtype(models.TextChoices):
        ACTIVE = "ACTIVE"
        JEANS = "JEANS"
        PANTS = "PANTS"
        SHORTS = "SHORTS"
        SKIRT = "SKIRT"

    class OuterwearSubtype(models.TextChoices):
        JACKET = "JACKET"
        COAT = "COAT"

    class DressSubtype(models.TextChoices):
        MINI = "MINI"
        MIDI = "MIDI"
        MAXI = "MAXI"

    class ShoesSubtype(models.TextChoices):
        ACTIVE = "ACTIVE"
        SNEAKERS = "SNEAKERS"
        BOOTS = "BOOTS"
        SANDALS_SLIDES = "SANDALS & SLIDES"

    class Precip(models.TextChoices):
        RAIN = "RAIN"
        SNOW = "SNOW"

    class Occasion(models.TextChoices):
        ACTIVE = "ACTIVE"
        CASUAL = "CASUAL"
        FORMAL = "FORMAL"

    class ClothingFit(models.TextChoices):
        LOOSE = "LOOSE"
        FITTED = "FITTED"
        TIGHT = "TIGHT"

    class Weather(models.TextChoices):
        WINTER = "WINTER"
        SPRING = "SPRING"
        SUMMER = "SUMMER"
        FALL = "FALL"

    def validate_subtype(value):
        # if no subtype is provided, skip validation (assuming field is optional)
        if not value:
            return

        ALLOWED_SUBTYPES = {
            [ClothingType.TOP]: TopSubtype,
            [ClothingType.BOTTOM]: BottomSubtype,
            [ClothingType.OUTERWEAR]: OuterwearSubtype,
            [ClothingType.DRESS]: DressSubtype,
            [ClothingType.SHOES]: ShoesSubtype
        }

        if self.type not in ALLOWED_SUBTYPES:
            raise ValidationError(
                f"Invalid clothing type '{self.type}'."
            )
        elif value not in ALLOWED_SUBTYPES[self.type]:
            raise ValidationError(
                f"Invalid subtype '{value}' for type '{self.type}'. valid options are: {', '.join(allowed)}."
            )


    type = models.CharField(choices=ClothingType)
    subtype = models.CharField(
        choices=TopSubtype.choices + BottomSubtype.choices + OuterwearSubtype.choices + DressSubtype.choices + ShoesSubtype.choices,
        blank=True,
        null=True,
        validators=[validate_subtype]
    )

    img_filename = models.URLField()

    # CIELAB color space color
    color_lstar = models.FloatField()
    color_astar = models.FloatField()
    color_bstar = models.FloatField()
    color_lstar_2nd = models.FloatField()
    color_astar_2nd = models.FloatField()
    color_bstar_2nd = models.FloatField()

    fit = models.CharField(choices=ClothingFit)

    # if true, this item can be worn on top of other items
    layerable = models.BooleanField(default=False)

    precip = models.CharField(choices=Precip, blank=True, null=True)

    occasion = models.CharField(choices=Occasion)

    weather = models.CharField(choices=Weather, default=Weather.SUMMER)

    created_at = models.DateTimeField(default=timezone.now)

    user = models.ForeignKey(User, on_delete=models.CASCADE)

    # Soft Delete for cluttering
    is_deleted = models.BooleanField(default=False)

class Tags(models.Model):
    label = models.CharField(blank=True)
    value = models.CharField()

    clothing = models.ForeignKey(Clothing, on_delete=models.CASCADE)

    user = models.ForeignKey(User, on_delete=models.CASCADE)

class Outfit(models.Model):
    id = models.BigAutoField(primary_key=True, unique=True)
    img_filename = models.URLField(blank=True, null=True)
    date_worn = models.DateTimeField(default=timezone.now)

class OutfitItem(models.Model):
    clothing = models.ForeignKey(Clothing, on_delete=models.CASCADE)

    outfit = models.ForeignKey(Outfit, on_delete=models.CASCADE)

### Signal handlers
@receiver(post_delete, sender=Clothing)
def clothing_post_delete(sender, instance, **kwargs):
        # Also delete relevant image from r2 to prevent orphaned data
        r2.delete_object(Bucket=IMAGE_BUCKET, Key=instance.img_filename)

### If introducing a new clothing type, add its subtypes to the mapping
TAG_MAPPINGS = {
    Clothing.ClothingType.TOP: Clothing.TopSubtype,
    Clothing.ClothingType.BOTTOM: Clothing.BottomSubtype,
    Clothing.ClothingType.DRESS: Clothing.DressSubtype,
    Clothing.ClothingType.OUTERWEAR: Clothing.OuterwearSubtype,
    Clothing.ClothingType.SHOES: Clothing.ShoesSubtype
}

### Extending any of the following categories will automatically be reflected here
BASE_TYPES = Clothing.ClothingType._member_names_
BASE_OCCASIONS = Clothing.Occasion._member_names_
BASE_FIT = Clothing.ClothingFit._member_names_
BASE_PRECIP = Clothing.Precip._member_names_
BASE_SUBTYPE = [
    {"type": typ, "subtypes": subtype._member_names_}
    for typ, subtype in TAG_MAPPINGS.items()
]
BASE_WEATHER = Clothing.Weather._member_names_
