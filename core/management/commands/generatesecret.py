from django.core.management.base import BaseCommand
import random
import string


class Command(BaseCommand):
  help = 'Creates a new secret key'

  def handle(self, *args, **options):
    output = ''
    for _ in range(50):
      output += random.choice(string.printable[:-6].replace("'", '').replace('"', ''))

    self.stdout.write(self.style.WARNING('This key just got randomly generated, set the current secret key with this one below: [This is only needed once]'))
    self.stdout.write(output)
