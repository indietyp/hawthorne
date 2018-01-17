from core.models import Country


def populate(strategy, details, backend, user=None, *args, **kwargs):
  information = details['player']

  if information['realname'] != '':
    information['realname'] = information['realname'].split(' ')

    user.first_name = information['realname'][0]

    if len(information['realname']) > 1:
      user.last_name = information['realname'][-1]

  user.steamid = information['steamid']
  user.country = Country.objects.get_or_create(code=information['loccountrycode'])[0]
  user.avatar = information['avatar']
  user.profile = information['profileurl']
  user.save()

  # if strategy == 'steam' and user is not None:
  #   print(user)
  #   print(details)
  #   print(type(details))
