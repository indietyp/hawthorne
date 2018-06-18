import json
import uuid

import requests
from django.conf import settings
from lxml import etree
from lxml.cssselect import CSSSelector
from steam import WebAPI


def search(query=''):
  # Request
  # GET https://steamcommunity.com/search/SearchCommunityAjax

  fake_session = uuid.uuid4().hex
  try:
    response = requests.get(
      url="https://steamcommunity.com/search/SearchCommunityAjax",
      params={
        "text": query,
        "filter": "users",
        "sessionid": fake_session,
        "steamid_user": "false",
        "page": "1",
      },
      headers={
        "Host": "steamcommunity.com",
        "Pragma": "no-cache",
        "Cookie": "sessionid=" + fake_session,
        "Content-Type": "multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__",
        "Referer": "https://steamcommunity.com/search/users/",
      },
      files={
      },
    )
    response = json.loads(response.content.decode())

    html = etree.HTML(response['html'])
    results = CSSSelector('div.search_row')
    credentials = CSSSelector('a.searchPersonaName')
    image = CSSSelector('div.avatarMedium img')

    output = []

    api = WebAPI(settings.SOCIAL_AUTH_STEAM_API_KEY)
    for result in results(html):
      tmp = {}
      tmp['name'] = credentials(result)[0].text

      uri = credentials(result)[0].attrib['href']
      if '/id/' in uri:
        response = api.ISteamUser.ResolveVanityURL(vanityurl=uri.split('/id/')[-1], url_type=1)
        tmp['url'] = response['response']['steamid']
      else:
        tmp['url'] = uri.split('/profiles/')[-1]

      tmp['image'] = image(result)[0].attrib['src']
      output.append(tmp)

    return output
  except requests.exceptions.RequestException:
    print('HTTP Request failed')
    return ''
