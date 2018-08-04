from django import forms

from core.models import Server


class ServerForm(forms.ModelForm):
  class Meta:
    model = Server
    fields = '__all__'
    widgets = {'password': forms.PasswordInput()}
