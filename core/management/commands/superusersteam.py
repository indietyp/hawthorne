from django.core.management.base import BaseCommand

from core.models import User


class Command(BaseCommand):
  help = 'Creates a superuser [custom]'

  def add_arguments(self, parser):
    parser.add_argument(
      '--steamid',
      action='store',
      dest='steam',
      help='creates a local superuser account - using steam',
    )

    parser.add_argument(
      '--check',
      action='store_true',
      dest='check',
      help='check first if an account already exists - if it does fail with a notice',
    )

  def handle(self, *args, **options):
    steamid = input('The SteamID64 of the superuser: ') if not options['steam'] else options['steam']

    if options['check'] and User.objects.filter(is_superuser=True):
      self.stdout.write(self.style.WARNING('Spotted that a superuser already exists. Abort.'))
      return

    user = User.objects.create_user(username=steamid, namespace="", is_active=True, is_staff=True, is_superuser=True, is_steam=True)
    user.save()

    self.stdout.write(self.style.SUCCESS('Succesfully created user'))
