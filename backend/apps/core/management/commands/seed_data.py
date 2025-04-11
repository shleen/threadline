import boto3
import django
import os
import random
import time

from django.core.management.base import BaseCommand
from django.utils import timezone

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from apps.core.models import User, Clothing, Tags, Outfit, OutfitItem
from apps.core.images import IMAGE_BUCKET, r2

class Command(BaseCommand):
    help = 'Populate the database with dummy seed data for ease of development.'

    def get_random_image_filename_for_user(self, user):
        """
        pick a random seed image from disk, upload it to r2,
        and return the generated filename for that user.
        """
        seed_images_folder = 'apps/core/management/assets/seed_images/'
        available_images = [
            f for f in os.listdir(seed_images_folder)
            if os.path.isfile(os.path.join(seed_images_folder, f))
            and f.lower().endswith(('.jpg', '.jpeg', '.png'))
        ]
        if not available_images:
            return None

        chosen_image = random.choice(available_images)
        filetype = chosen_image.split('.')[-1]
        unique_filename = f"{user.username}_{round(time.time() * 1000)}.{filetype}"

        local_path = os.path.join(seed_images_folder, chosen_image)
        with open(local_path, 'rb') as image_file:
            r2.upload_fileobj(image_file, IMAGE_BUCKET, unique_filename)

        return unique_filename

    def handle(self, *args, **options):
        user1 = User.objects.create(username="alice")
        user2 = User.objects.create(username="bob")

        clothing_types = [
            (Clothing.ClothingType.TOP, Clothing.TopSubtype.T_SHIRT),
            (Clothing.ClothingType.BOTTOM, Clothing.BottomSubtype.JEANS),
            (Clothing.ClothingType.OUTERWEAR, Clothing.OuterwearSubtype.JACKET),
            (Clothing.ClothingType.DRESS, Clothing.DressSubtype.MINI),
            (Clothing.ClothingType.SHOES, Clothing.ShoesSubtype.SNEAKERS)
        ]

        fits = [
            Clothing.ClothingFit.LOOSE,
            Clothing.ClothingFit.FITTED,
            Clothing.ClothingFit.TIGHT
        ]
        occasions = [
            Clothing.Occasion.ACTIVE,
            Clothing.Occasion.CASUAL,
            Clothing.Occasion.FORMAL
        ]
        precips = [None, Clothing.Precip.RAIN, Clothing.Precip.SNOW]

        weathers = [
            Clothing.Weather.SUMMER,
            Clothing.Weather.WINTER
        ]

        for user in [user1, user2]:
            for i in range(100):
                ctype, subtype = random.choice(clothing_types)
                color_l = random.uniform(0, 100)
                color_a = random.uniform(-128, 128)
                color_b = random.uniform(-128, 128)
                color_l_2nd = random.uniform(0, 100)
                color_a_2nd = random.uniform(-128, 128)
                color_b_2nd = random.uniform(-128, 128)
                fit = random.choice(fits)
                occasion = random.choice(occasions)
                precipitation = random.choice(precips)
                weather = random.choice(weathers)
                layerable = bool(random.getrandbits(1))
                is_deleted = False

                # upload a random local image to r2
                random_image_filename = self.get_random_image_filename_for_user(user)
                if not random_image_filename:
                    img_filename = "no_local_image_found.jpg"
                else:
                    img_filename = random_image_filename

                clothing_item = Clothing.objects.create(
                    type=ctype,
                    subtype=subtype,
                    img_filename=img_filename,
                    color_lstar=color_l,
                    color_astar=color_a,
                    color_bstar=color_b,
                    color_lstar_2nd=color_l_2nd,
                    color_astar_2nd=color_a_2nd,
                    color_bstar_2nd=color_b_2nd,
                    fit=fit,
                    layerable=layerable,
                    precip=precipitation,
                    occasion=occasion,
                    weather=weather,
                    user=user,
                    is_deleted = is_deleted
                )

                # attach some tags
                Tags.objects.create(
                    label="brand",
                    value=f"brand_{i}",
                    clothing=clothing_item,
                    user=user
                )
                Tags.objects.create(
                    label="random",
                    value=f"tag_{random.randint(100, 999)}",
                    clothing=clothing_item,
                    user=user
                )

        # create outfits
        outfit1 = Outfit.objects.create(date_worn=timezone.now())
        outfit2 = Outfit.objects.create(date_worn=timezone.now())

        # relate clothing items to outfits
        all_clothing = list(Clothing.objects.all())
        random_clothes = random.sample(all_clothing, min(5, len(all_clothing)))
        for c in random_clothes:
            OutfitItem.objects.create(clothing=c, outfit=outfit1)

        random_clothes_2 = random.sample(all_clothing, min(5, len(all_clothing)))
        for c in random_clothes_2:
            OutfitItem.objects.create(clothing=c, outfit=outfit2)

        print("Seed data created successfully.")
