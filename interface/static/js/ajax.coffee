admin__admin = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.admin.user[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      if page == 1
        $("#admin__admin").html('')

      $("#admin__admin").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.admins(page + 1)

    else
      return false
  )

admin__log = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.admin.log[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      $("#admin__log").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.logs(page + 1)
    else
      return false
  )

admin__group = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.admin.group[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      if page == 1
        i = 0
        for item in $("#admin__group .row")
          if i != 0
            $(item).remove()
          i++

      $("#admin__group").htmlAppend(data)
      feather.replace()

      return window.ajax.admin.groups(page + 1)
    else
      return false
  )

ban__user = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.ban.user[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      if page == 1
        $("#ban__user").html('')
      $("#ban__user").htmlAppend(data)
      feather.replace()

      return window.ajax.ban.user(page + 1)
    else
      return false
  )

chat__log = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.chat.log[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      $("#chat__log").htmlAppend(data)
      feather.replace()

      return window.ajax.chat.logs(page + 1)
    else
      return false
  )

mutegag__user = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.mutegag.user[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      if page == 1
        $("#mutegag__user").html('')

      $("#mutegag__user").htmlAppend(data)
      feather.replace()

      return window.ajax.mutegag.user(page + 1)
    else
      return false
  )

player__user = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.player.user[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      $("#player__user").htmlAppend(data)
      feather.replace()

      return window.ajax.mutegag.user(page + 1)
    else
      return false
  )


server__server = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.server.server[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      if page == 1
        i = 0
        for item in $("#server__server .row")
          if i != 0
            $(item).remove()
          i++

      $("#server__server").htmlAfter(data)

      $("script.server.execution").forEach((src) ->
        eval(src.innerHTML)
      )

      feather.replace()

      return window.ajax.server.server(page + 1)
    else
      return false
  )

home__instance = (page = 1) ->
  header =
    "X-CSRFToken": window.csrftoken

  window.endpoint.ajax.home.server[page].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    if status == 200
      $("#home__instance").htmlAppend data
      feather.replace()

      return window.ajax.home.instance(page + 1)
    else
      return false
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
  home:
    instance: home__instance
