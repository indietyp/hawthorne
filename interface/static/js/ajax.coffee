admin__admin = (page=1) ->
  if page == 1
    $("#admin__admin").html('')

  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/admin/user/' + page, 'POST', (data, status) ->
    if status == 200
      $("#admin__admin").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.admins(page+1)
    else
      return false

    return true
  )

admin__log = (page=1) ->
  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/admin/log/' + page, 'POST', (data, status) ->
    if status == 200
      $("#admin__log").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.logs(page+1)
    else
      return false

    return true
  )

admin__group = (page=1) ->
  if page == 1
    i = 0
    for item in $("#admin__group .row")
      if i != 0
        $(item).remove()
      i++

  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/admin/group/' + page, 'POST', (data, status) ->
    if status == 200
      $("#admin__group").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.groups(page+1)
    else
      return false

    return true
  )

ban__user = (page=1) ->
  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/ban/user/' + page, 'POST', (data, status) ->
    if status == 200
      $("#ban__user").htmlAppend(data)
      feather.replace()

      return window.ajax.ban.user(page+1)
    else
      return false

    return true
  )

chat__log = (page=1) ->
  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/chat/log/' + page, 'POST', (data, status) ->
    if status == 200
      $("#chat__log").htmlAppend(data)
      feather.replace()

      return window.ajax.chat.logs(page+1)
    else
      return false

    return true
  )

mutegag__user = (page=1) ->
  if page == 1
    $("#mutegag__user").html('')

  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/mutegag/user/' + page, 'POST', (data, status) ->
    if status == 200
      $("#mutegag__user").htmlAppend(data)
      feather.replace()

      return window.ajax.mutegag.user(page+1)
    else
      return false

    return true
  )

player__user = (page=1) ->
  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/player/user/' + page, 'POST', (data, status) ->
    if status == 200
      $("#player__user").htmlAppend(data)
      feather.replace()

      return window.ajax.mutegag.user(page+1)
    else
      return false

    return true
  )

server__server = (page=1) ->
  $({'csrfmiddlewaretoken': window.csrftoken}).ajax('/ajax/v1/server/server/' + page, 'POST', (data, status) ->
    if status == 200
      $("#server__server").htmlAfter(data)

      for scr in $(".chart-section script.execution")
        eval($(scr).html())

      feather.replace()

      return window.ajax.server.server(page+1)
    else
      return false

    return true
  )

window.ajax =
  admin:
    admins: admin__admin
    logs: admin__log
    groups: admin__group
  ban:
    user: ban__user
  chat:
    logs: chat__log
  mutegag:
    user: mutegag__user
  player:
    user: player__user
  server:
    server: server__server
