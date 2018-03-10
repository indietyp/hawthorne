search = (query, that=null, internal=false) ->
  ts = new Date().getTime()
  window.cache.steam =
    _ts: ts

  window.endpoint.api.steam.search[Number(internal)]({'query': query, '_ts': ts}).get((err, data) ->
    data = data.result

    if data._ts < window.cache.steam._ts
      return false

    data = data.data
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
