import os

from celery import Celery


os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'panel.settings')


app = Celery('panel')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()


@app.task()
def test(arg):
  print(arg)
