# Generated by Django 2.0.3 on 2018-03-16 22:03

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('log', '0003_auto_20180312_2204'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='userip',
            options={'permissions': [('view_capabilities', 'Can view the current capabilities')]},
        ),
        migrations.AlterModelOptions(
            name='usernamespace',
            options={'permissions': [('view_capabilities', 'Can view the current capabilities')]},
        ),
        migrations.AlterModelOptions(
            name='useronlinetime',
            options={'permissions': [('view_capabilities', 'Can view the current capabilities')]},
        ),
    ]
