# view controller

change = (destination = 'home') ->
  method = 'POST'

  switch destination
    when 'home'
      url = ''
    when 'player'
      url = 'players'
    when 'admin'
      url = 'admins'
    when 'server'
      url = 'servers'
    when 'ban'
      url = 'bans'
    when 'mutegag'
      url = 'mutegags'
    when 'announcements'
      url = 'announcements'
    when 'chat'
      url = 'chat'
    when 'settings'
      url = 'settings'
    else
      return false

  header =
    'X-CSRFTOKEN': window.csrftoken

  window.endpoint.bare[url].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data

    if status == 200
      $("#content").css('opacity', '0')

      setTimeout(->
        $("#content")[0].innerHTML = data
        $("#content script.execution").forEach((scr) ->
          eval(scr.innerHTML)
        )
        feather.replace()
        $("#content").css('opacity', '')
      , 300)
    else
      return false

    url = if not url then '/' else url
    window.history.pushState "", "", url
    return true
  )

  return true


ajax = (destination, module) ->
  return true

window.vc =
  change: change
