# Generated by Django 2.0.5 on 2018-06-02 21:45

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0061_auto_20180528_0951'),
    ]

    operations = [
        migrations.AddField(
            model_name='punishment',
            name='is_kicked',
            field=models.BooleanField(default=False),
        ),
    ]