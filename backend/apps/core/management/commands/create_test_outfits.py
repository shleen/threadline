import django
import os
import random

from django.core.management.base import BaseCommand
from django.utils import timezone

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from apps.core.models import Clothing, Outfit, OutfitItem

class Command(BaseCommand):
    help = 'Create two test outfits using existing clothing items'

    def handle(self, *args, **options):
        # create outfits
        outfit1 = Outfit.objects.create(date_worn=timezone.now())
        outfit2 = Outfit.objects.create(date_worn=timezone.now())

        # relate clothing items to outfits
        all_clothing = list(Clothing.objects.all())
        if not all_clothing:
            self.stdout.write(self.style.ERROR('No clothing items found in database'))
            return

        random_clothes = random.sample(all_clothing, min(5, len(all_clothing)))
        for c in random_clothes:
            OutfitItem.objects.create(clothing=c, outfit=outfit1)

        random_clothes_2 = random.sample(all_clothing, min(5, len(all_clothing)))
        for c in random_clothes_2:
            OutfitItem.objects.create(clothing=c, outfit=outfit2)

        self.stdout.write(self.style.SUCCESS('Created 2 test outfits successfully')) 