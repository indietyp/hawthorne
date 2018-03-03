from django.core.management.base import BaseCommand
from core.models import User


class Command(BaseCommand):
  help = 'Creates a superuser [custom]'

  def add_arguments(self, parser):
    # parser.add_argument('poll_id', nargs='+', type=int)
    parser.add_argument(
        '--steamid',
        action='store',
        dest='steam',
        help='creates a local superuser account - using steam',
    )

  def handle(self, *args, **options):
    steamid = input('The SteamID64 of the superuser: ') if options['steam'] is None else options['steam']

    user = User.objects.create_user(username=steamid, is_active=True, is_staff=True, is_superuser=True, steam=True)
    user.save()

    self.stdout.write(self.style.SUCCESS('Succesfully created user'))
