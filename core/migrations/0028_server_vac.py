# Generated by Django 2.0 on 2018-02-17 20:44

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0027_server_mode'),
    ]

    operations = [
        migrations.AddField(
            model_name='server',
            name='vac',
            field=models.BooleanField(default=True),
        ),
    ]
