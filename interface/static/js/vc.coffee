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
    when 'admins[servers]'
      url = 'admins/servers'
    when 'admins[web]'
      url = 'admins/web'
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
      window.history.pushState "", "", "/" + url

      $(".main")[0].innerHTML = data
      $(".main script.execute:not(.evaluated)").forEach((scr) ->
        eval scr.innerHTML
      )

  )

window.vc = load
