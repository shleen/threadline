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

    fit = models.CharField(choices=ClothingFit)

    # if true, this item can be worn on top of other items
    layerable = models.BooleanField(default=False)

    precip = models.CharField(choices=Precip, blank=True, null=True)

    occasion = models.CharField(choices=Occasion)

    winter = models.BooleanField()

    created_at = models.DateTimeField(default=timezone.now)

    user = models.ForeignKey(User, on_delete=models.CASCADE)


class Tags(models.Model):
    label = models.CharField(blank=True)
    value = models.CharField()

    clothing = models.ForeignKey(Clothing, on_delete=models.CASCADE)

    user = models.ForeignKey(User, on_delete=models.CASCADE)


class Outfit(models.Model):
    date_worn = models.DateTimeField(default=timezone.now)

class OutfitItem(models.Model):
    clothing = models.ForeignKey(Clothing, on_delete=models.CASCADE)

    outfit = models.ForeignKey(Outfit, on_delete=models.CASCADE)


### Signal handlers
@receiver(post_delete, sender=Clothing)
def clothing_post_delete(sender, instance, **kwargs):
        # Also delete relevant image from r2 to prevent orphaned data
        r2.delete_object(Bucket=IMAGE_BUCKET, Key=instance.img_filename)
