request = (endpoint, options, payload, method, target) ->
  endpoint[method](options, {}, payload, (err, data) ->
    if data.success
      target.reset()
  )


single = (mode = '', target) ->
  payload = {}
  options =
    toast: true
  method = 'put'
  component = undefined

  validated = true
  Array.from(target.elements).forEach (e) ->
    if $(e).hasClass 'skip'
      return

    value = window.api.utils.transform e
    valid = window.api.utils.validation e

    if not valid[0]
      validated = false
      $(e).addClass 'invalid'
      console.log valid
      $('span span.invalid', $(e).parent())[0].innerHTML = valid[1]

      return


    if $(e).hasClass 'target'
      component = value
      return

    name = e.name
    if e.hasAttribute 'data-name'
      name = e.getAttribute 'data-name'

    if e.hasAttribute 'multiple'
      options = Array.from e.options
      payload[name] = options.map((x) -> x.value)
    else if e.hasAttribute('data-boolean')
      payload[e.getAttribute('data-boolean')] = e.checked
    else if e.getAttribute('type') is 'checkbox'
      if not e.checked
        return
      if not payload.hasOwnProperty e.name
        payload[name] = []
      payload[name].push value
    else if e.hasAttribute 'data-list'
      payload[name] = [value]
    else if name.includes('/') and value.constructor.name == 'Array'

      values = []
      names = name.split('/')
      for i in [0..names.length] by 1
        values.push [names[i], value[i]]

      values.forEach (v) ->
        payload[v[0]] = v[1]

    else if value
      payload[name] = value

  if not validated
    return

  switch mode
    when 'admins[web][groups]'
      endpoint = window.endpoint.api.groups
    when 'admins[web][admins]'
      method = 'post'
      endpoint = window.endpoint.api.users[component]
    when 'admins[server][roles]'
      endpoint = window.endpoint.api.roles
    when 'admins[server][admins]'
      method = 'post'
      endpoint = window.endpoint.api.users[component]
    when 'players[detailed][punishment]'
      endpoint = window.endpoint.api.users[component].punishments
    when 'servers'
      endpoint = window.endpoint.api.servers

  if target.hasAttribute 'data-append'
    endpoint.get({}, {}, {}, (err, data) ->
      field = target.getAttribute 'data-append'
      payload[field] = data.result[field].concat payload[field]
      request endpoint, options, payload, method, target
    )
  else
    request endpoint, options, payload, method, target

  return

create = (mode = '', target, batch = false) ->
  if batch
    targets = window.batch
    window.batch = []
  else
    targets = [target]

  targets.forEach((element) ->
    single(mode, element)
  )

  return

window.api.create = create
