# view controller

load = (destination = 'home', scope = '') ->
  window.batch = []
  endpoint = window.endpoint.bare

  switch destination
    when 'home'
      url = ''
    when 'settings'
      url = 'settings'
    when 'servers'
      url = 'servers'
    when 'servers[detailed]'
      url = "servers/#{scope}"
    when 'admins[servers]'
      url = 'admins/servers'
    when 'admins[web]'
      url = 'admins/web'
    when 'players'
      url = 'players'
    when 'players[detailed]'
      url = "players/#{scope}"
    when 'punishments'
      url = '[[PLACEHOLDER]]'
    when 'punishments[bans]'
      url = 'punishments/bans'
    when 'punishments[mutes]'
      url = 'punishments/mutes'
    when 'punishments[gags]'
      url = 'punishments/gags'
    else
      return

  header =
    'X-CSRFTOKEN': window.csrftoken

  window._.location = destination
  window._.scope = scope
  window.endpoint.bare[url].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data

    if status is 200
      window.history.pushState {location: destination, scope: scope}, null, "/#{url}"

      $('.overlay').fadeOut 'fast'
      $('.modal').fadeOut 'fast'

      $('.main')[0].innerHTML = data
      $('.main script.execute:not(.evaluated)').forEach((scr) ->
        eval scr.innerHTML
      )

  )


window.onpopstate = (event) ->
  # console.log event

  if not event.state or event.state.skip
    window.history.back()
  else
    window.vc event.state.location, event.state.scope
  return

window.vc = load
