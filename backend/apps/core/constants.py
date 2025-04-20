from .models import *

# Represents the "types" of outfits that can be worn. If a user has both dresses and pants
# in their wardrobe, an outfit ALWAYS contains EITHER a dress OR a (top + bottom). To codify
# this relationship, we have a list of tuples, where each tuple contains an anchor type and
# a list of exclusions - clothing types that should not co-exist in an outfit. This is
# extensible to support more complex relationships in the future.
OUTFIT_TYPES = [
    {
        'anchor': Clothing.ClothingType.DRESS,
        'exclusions': [Clothing.ClothingType.TOP, Clothing.ClothingType.BOTTOM]
    },
    {
        'anchor': Clothing.ClothingType.TOP,
        'exclusions': [Clothing.ClothingType.DRESS]
    }
]
