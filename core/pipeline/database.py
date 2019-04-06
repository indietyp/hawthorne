from core.models import Country


def populate(strategy, details, backend, user=None, *args, **kwargs):
  if backend.name == 'steam' and user is not None:
    information = details['player']

    if 'realname' in information and information['realname']:
      information['realname'] = information['realname'].split(' ')

      user.first_name = information['realname'][0][:30]

      if len(information['realname']) > 1:
        user.last_name = information['realname'][-1][:150]

    user.namespace = information['personaname']

    # switch to IP based country when not present yet
    if 'loccountrycode' in information and information['loccountrycode'] and not user.country:
      user.country = Country.objects.get_or_create(code=information['loccountrycode'].lower())[0]

    user.avatar = information['avatarfull']
    user.profile = information['profileurl']
    user.save()
