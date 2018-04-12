from django.contrib.auth.decorators import login_required
from django.shortcuts import render


def home(request):
  return render(request, 'main.pug', {})


def mail(request):
  return render(request, 'mail.pug', {})


def login(request):
  return render(request, 'login.pug', {})


@login_required(login_url='/login')
def dashboard(request):
  return render(request, 'main.pug', {})
