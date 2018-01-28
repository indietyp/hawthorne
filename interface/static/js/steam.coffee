search = (query, that=null) ->
  $({'query': query}).ajax('/api/v1/steam/search', 'GET', (data, status) ->
    data = JSON.parse data
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        formatted.push {'value': ele.url, 'label': "<img class='inner-dropdown-image' src='#{ele.image}' />#{ele.name}"}
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

window.steam =
  search: search
