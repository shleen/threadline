# Generated by Django 5.1.5 on 2025-04-20 02:47

import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0007_alter_clothing_weather'),
    ]

    operations = [
        migrations.CreateModel(
            name='OutfitLike',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('outfit', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='core.outfit')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='core.user')),
            ],
            options={
                'unique_together': {('outfit', 'user')},
            },
        ),
    ]
