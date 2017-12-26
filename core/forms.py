from django import forms
from core.models import Server


class ServerForm(forms.ModelForm):
  class Meta:
    model = Server
    widgets = {'password': forms.PasswordInput()}
