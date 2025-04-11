import django
import os
import random
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from apps.core.models import Clothing, Outfit, OutfitItem

class Command(BaseCommand):
    help = 'Create outfit history across the past week with some rewears'

    def handle(self, *args, **options):
        # Get all clothing items
        tops = list(Clothing.objects.filter(type='TOP'))
        bottoms = list(Clothing.objects.filter(type='BOTTOM'))
        shoes = list(Clothing.objects.filter(type='SHOES'))
        outerwear = list(Clothing.objects.filter(type='OUTERWEAR'))
        dresses = list(Clothing.objects.filter(type='DRESS'))

        if not (tops and bottoms and shoes):
            self.stdout.write(self.style.ERROR('Not enough clothing items found'))
            return

        # Create outfits for the past 7 days
        now = timezone.now()
        
        # Pick some items to be "favorites" that will be reworn
        favorite_top = random.choice(tops) if tops else None
        favorite_bottom = random.choice(bottoms) if bottoms else None
        favorite_shoes = random.choice(shoes) if shoes else None
        
        for days_ago in range(7):
            date = now - timedelta(days=days_ago)
            
            # Create 1-2 outfits per day
            for _ in range(random.randint(1, 2)):
                outfit = Outfit.objects.create(date_worn=date)
                
                # Decide between dress outfit (20% chance) or top/bottom outfit
                if dresses and random.random() < 0.2:
                    # Dress outfit
                    items = [
                        random.choice(dresses),
                        # 50% chance to use favorite shoes, otherwise random
                        favorite_shoes if random.random() < 0.5 else random.choice(shoes)
                    ]
                else:
                    # Top/bottom outfit
                    items = [
                        # 60% chance to use favorite top if it's been 2+ days
                        favorite_top if days_ago >= 2 and random.random() < 0.6 else random.choice(tops),
                        # 60% chance to use favorite bottom if it's been 2+ days
                        favorite_bottom if days_ago >= 2 and random.random() < 0.6 else random.choice(bottoms),
                        # 50% chance to use favorite shoes
                        favorite_shoes if random.random() < 0.5 else random.choice(shoes)
                    ]
                
                # Add outerwear 70% of the time
                if outerwear and random.random() < 0.7:
                    items.append(random.choice(outerwear))
                
                # Create outfit items
                for item in items:
                    OutfitItem.objects.create(outfit=outfit, clothing=item)
        
        self.stdout.write(
            self.style.SUCCESS('Successfully created outfit history across past week')
        ) 