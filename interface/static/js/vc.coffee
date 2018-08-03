# view controller

load = (destination='home', scope='') ->
  endpoint = window.endpoint.bare

  switch destination
    when 'home'
      url = ""
    when 'servers'
      url = "servers"
    when 'servers[detailed]'
      url = "servers/#{scope}"
    when 'punishments'
      url = "[[PLACEHOLDER]]"
    when 'punishments[bans]'
      url = "punishments/bans"
    when 'punishments[mutes]'
      url = "punishments/mutes"
    when 'punishments[gags]'
      url = "punishments/gags"
    else
      return

  header =
    'X-CSRFTOKEN': window.csrftoken

  window.endpoint.bare[url].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data

    if status == 200
      $(".main")[0].innerHTML = data
      $(".main script.execute").forEach((scr) ->
        eval(scr.innerHTML)
      )

      url = "/" + url
      window.history.pushState "", "", url
  )

window.vc = load
