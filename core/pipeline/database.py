from core.models import Country


def populate(strategy, details, backend, user=None, *args, **kwargs):
  information = details['player']

  print(information)
  if information['realname'] != '':
    information['realname'] = information['realname'].split(' ')

    user.first_name = information['realname'][0]

    if len(information['realname']) > 1:
      user.last_name = information['realname'][-1]

  user.ingame = information['username']
  user.country = Country.objects.get_or_create(code=information['loccountrycode'])[0]
  user.avatar = information['avatar']
  user.profile = information['profileurl']
  user.save()

  if strategy == 'steam' and user is not None:
    print('triggered')
