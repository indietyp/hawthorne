#= require api.delete.coffee
#= require api.edit.coffee
#= require api.create.coffee

game = (that = null, selected = '') ->
  window.endpoint.api.capabilities.games.get((err, data) ->
    data = data.result


    if that != null
      formatted = []
      for ele in data
        fmt =
          value: ele.value
          label: ele.label

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

server = (query, that = null, selected = '') ->
  window.endpoint.api.servers({'query': query}).get((err, data) ->
    data = data.result

    if that != null
      formatted = [{'value': 'all', 'label': '<b>all</b>'}]

      if selected == 'all'
        formatted[0].selected = true

      for ele in data
        fmt =
          value: ele.id
          label: ele.name

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

role = (query, that = null, selected = '') ->
  window.endpoint.api.roles({'match': query}).get((err, data) ->
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        fmt =
          value: ele.id
          label: ele.name
          customProperties:
            server: ele.server

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

group = (query, that = null, selected = '') ->
  window.endpoint.api.groups({'match': query}).get((err, data) ->
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        fmt =
          value: ele.id
          label: ele.name

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

setup = (that) ->
  node = that.parentNode.parentNode
  header =
    "X-CSRFToken": window.csrftoken

  payload =
    username: $('input.username', node)[0].value
    password: $('input.password', node)[0].value

  uuid = $('input.uuid', node)[0].value

  fermata.json("/setup")[uuid].put(header, payload, (err, data) ->
    window.location.href = "/login";
  )

login = (that) ->
  node = that.parentNode.parentNode
  header =
    "X-CSRFToken": window.csrftoken
    'Content-Type': "application/x-www-form-urlencoded; charset=utf-8"

  # payload =
  #   username: $('input.username', node)[0].value
  #   password: $('input.password', node)[0].value

  payload = "username=#{$('input.username', node)[0].value}&password=#{$('input.password', node)[0].value}"

  fermata.raw({base: window.location.origin + "/internal/login"}).post(header, payload, (dummy, data) ->
    window.location.href = "/";
  )

window.api.servers = server
window.api.roles = role
window.api.groups = group
window.api.games = game
window.api.setup = setup
window.api.login = login
