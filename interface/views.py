from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from core.models import Server
from django.utils import formats


def login(request):
  return render(request, 'skeleton/login.pug', {})


@login_required(login_url='/login')
def home(request):
  return render(request, 'components/home.pug', {})


@login_required(login_url='/login')
def player(request):
  return render(request, 'components/player.pug', {})


@login_required(login_url='/login')
def admin(request):
  return render(request, 'components/admin.pug', {})


@login_required(login_url='/login')
def server(request):
  return render(request, 'components/server.pug', {'supported': [{'label': x[1], 'value': x[0]} for x in Server.SUPPORTED]})


@login_required(login_url='/login')
def ban(request):
  return render(request, 'components/ban.pug', {})


@login_required(login_url='/login')
def mutegag(request):
  return render(request, 'components/mutegag.pug')


@login_required(login_url='/login')
def announcement(request):
  return render(request, 'components/home.pug', {})


@login_required(login_url='/login')
def chat(request):
  return render(request, 'components/chat.pug', {})


@login_required(login_url='/login')
def settings(request):
  return render(request, 'components/home.pug', {})


def dummy(request):
  return render(request, 'skeleton/main.pug', {})
