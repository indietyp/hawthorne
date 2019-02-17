import sys
import traceback

from django.core.management.base import BaseCommand
from lib.importer import Importer
from urllib.parse import urlparse


class Command(BaseCommand):
  help = 'Toolset to import data from external systems into hawthorne.'

  def add_arguments(self, parser):
    parser.add_argument(
        'database',
        action='store',
        help='mysql://<user>:<password>@<host>:<port>/<database> ' +
             '(Reference: RFC 1808 and RFC1738 Section 3.1)',
        metavar='DATABASE'
    )

    parser.add_argument(
        '--system', '-s',
        action='store',
        dest='system',
        help='Currently %(choices)s are supported. %(default)s is the default.',
        choices=['sourcebans', 'boompanel', 'sourcemod'],
        metavar='SYSTEM',
        default='sourcebans'
    )

  def handle(self, system, database, *args, **options):
    connection = database if database.startswith('mysql://') else 'mysql://' + database
    connection = urlparse(connection)

    importer = Importer(connection.hostname,
                        connection.port if connection.port else 3306,
                        connection.username,
                        connection.password,
                        connection.path[1:])

    sys.stdout = open('/var/log/hawthorne/import.log', 'w')
    try:
      if system == 'sourcebans':
        importer.sourceban()
      elif system == 'boompanel':
        importer.boompanel()
      elif system == 'sourcemod':
        importer.sourcemod()
    except Exception as e:
      print(e)
      traceback.print_exc(file=sys.stdout)

      sys.stdout = sys.__stdout__

      self.stdout.write(self.style.ERROR('The import has failed due to {}'.format(e)))
      self.stdout.write("The traceback is located in /var/log/hawthorne/import.log")

      return

    sys.stdout = sys.__stdout__
    self.stdout.write(self.style.SUCCESS('The import has been successfully finished.'))
