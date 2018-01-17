import requests
import uuid
import json
from lxml import etree
from lxml.cssselect import CSSSelector


def search(query=''):
  # Request
  # GET http://steamcommunity.com/search/SearchCommunityAjax

  fake_session = uuid.uuid4().hex
  try:
    response = requests.get(
        url="http://steamcommunity.com/search/SearchCommunityAjax",
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
            "Referer": "http://steamcommunity.com/search/users/",
        },
        files={
        },
    )
    response = json.loads(response.content)

    html = etree.HTML(response['html'])
    results = CSSSelector('div.search_row')
    credentials = CSSSelector('a.searchPersonaName')
    image = CSSSelector('div.avatarMedium img')

    output = []
    for result in results(html):
        tmp = {}
        tmp['name'] = credentials(result)[0].text
        tmp['url'] = credentials(result)[0].attrib['href']
        tmp['image'] = image(result)[0].attrib['src']

        output.append(tmp)

    return output
  except requests.exceptions.RequestException:
    print('HTTP Request failed')
    return ''
