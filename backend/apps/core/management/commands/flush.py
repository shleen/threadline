from django.core.management.commands.flush import Command as FlushCommand
from django.core.management import call_command
from django.db import connection

from apps.core.models import Clothing

class Command(FlushCommand):
    """
    Overrides django's flush command to first delete all clothing objects
    (and the associated r2 images) so we don't leave orphaned data behind.
    """

    def handle(self, **options):
        # first, remove all Clothing objects via .delete()
        # so that our post_delete signal can do the r2 cleanup
        qs = Clothing.objects.all()
        count = qs.count()
        for c in qs:
            c.delete()

        # now call the standard flush logic from django
        super().handle(**options)

        self.stdout.write("DB flush complete.")
