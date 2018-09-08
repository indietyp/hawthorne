# view controller

load = (destination = 'home', scope = '') ->
  endpoint = window.endpoint.bare

  switch destination
    when 'home'
      url = ''
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

      $('.main')[0].innerHTML = data
      $('.main script.execute:not(.evaluated)').forEach((scr) ->
        eval scr.innerHTML
      )

  )


$(window).on('popstate', (event) ->
  # this is like super janked with the even state and I have no clue why
  # --> so we just gonna reload that bitch
  # console.log event
  # window.vc event.state.location, event.state.scope
  console.log event
  # window.location.href = location.href
  return
)

window.vc = load
