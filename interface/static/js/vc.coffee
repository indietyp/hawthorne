# view controller

change = (destination='home') ->
  method = 'POST'

  switch destination
    when 'home'
      url = '/'
    when 'player'
      url = '/players'
    when 'admin'
      url = '/admins'
    when 'server'
      url = '/servers'
    when 'ban'
      url = '/bans'
    when 'mutegag'
      url = '/mutegags'
    when 'announcements'
      url = '/announcements'
    when 'chat'
      url = '/chat'
    when 'settings'
      url = '/settings'
    else
      return false

  data =
    csrfmiddlewaretoken: $("[name=csrfmiddlewaretoken]").val()

  $(data).ajax(url, method, (data, status) ->
    if status == 200
      $("#content").css('opacity', '0')

      setTimeout(->
        $("#content").html(data)
        eval($("#content script.execution").html())
        feather.replace()
        $("#content").css('opacity', '')
      , 200)
    else
      return false

    window.history.pushState "", "", url
    return true
  )

  return true


ajax = (destination, module) ->
  return true

window.vc =
  change: change
