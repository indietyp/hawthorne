from django.core.management.base import BaseCommand
from lib.importer import Importer


class Command(BaseCommand):
  help = 'Imports from different external systems'

  def add_arguments(self, parser):
    parser.add_argument(
      '--mode',
      action='store',
      dest='mode',
      help='Currently supported: sourcemod, boompanel',
    )

    parser.add_argument(
      '--host',
      action='store',
      dest='host',
      help='DB Host',
    )

    parser.add_argument(
      '--user',
      action='store',
      dest='user',
      help='DB User',
    )

    parser.add_argument(
      '--password',
      action='store',
      dest='pwd',
      help='DB Password',
    )

    parser.add_argument(
      '--database',
      action='store',
      dest='db',
      help='DB Database',
    )


  def handle(self, mode, host, user, pwd, db, *args, **options):
    mode = mode.lower()
    if mode not in ['sourcemod', 'boompanel']:
      self.stdout.write(self.style.WARNING('Currently your selected mode is not available'))
      return

    domain = host.split(":")[0]
    port = int(host.split(":")[1])
    importer = Importer(domain, port, user, pwd, db)

    if mode == 'sourcemod':
      importer.sourcemod()
    elif mode == 'boompanel':
      importer.boompanel()

    self.stdout.write(self.style.SUCCESS('Successfully imported'))
