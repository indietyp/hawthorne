# Generated by Django 2.0.3 on 2018-03-19 21:50

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0049_auto_20180319_2140'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='country',
            options={'default_permissions': (), 'permissions': [], 'verbose_name': 'country', 'verbose_name_plural': 'countries'},
        ),
        migrations.AlterModelOptions(
            name='membership',
            options={'default_permissions': (), 'permissions': ()},
        ),
        migrations.AlterModelOptions(
            name='serverpermission',
            options={'default_permissions': (), 'permissions': ()},
        ),
    ]
