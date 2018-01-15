from django.contrib.auth.decorators import login_required
from django.shortcuts import render


def login(request):
  return render(request, 'skeleton/login.pug', {})


@login_required(login_url='/login')
def home(request):
  return render(request, 'components/home.pug', {})


def dummy(request):
  return render(request, 'skeleton/main.pug', {})
