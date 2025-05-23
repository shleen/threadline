# Generated by Django 5.1.5 on 2025-04-09 21:50

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0003_remove_clothing_winter_clothing_weather'),
    ]

    operations = [
        migrations.AddField(
            model_name='clothing',
            name='color_astar_2nd',
            field=models.FloatField(default=0),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='clothing',
            name='color_bstar_2nd',
            field=models.FloatField(default=0),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='clothing',
            name='color_lstar_2nd',
            field=models.FloatField(default=0),
            preserve_default=False,
        ),
    ]
