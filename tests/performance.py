#!/usr/bin/env python
import os
import sys

current = os.path.dirname(os.path.abspath(__file__))
parent = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(parent)
sys.path.append(parent)

os.environ.setdefault(
    'DJANGO_SETTINGS_MODULE',
    'panel.settings'
)

import django
django.setup()

from core.models import User
from django.core.servers.basehttp import get_internal_wsgi_application
from django.test.client import RequestFactory

factory = RequestFactory()
user = User.objects.filter()[0]

request = factory.get('/admins/web')
request.session = {}
request._cached_user = user
request.user = user

app = get_internal_wsgi_application()

import cProfile, pstats, io
pr = cProfile.Profile()
pr.enable()
app.get_response(request).content.decode()
pr.disable()

s = io.StringIO()
sortby = 'cumulative'
ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
ps.print_stats(10)
print(s.getvalue())


os.chdir(current)
