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

  Array.from(target.elements).forEach (e) ->
    if $(e).hasClass 'skip'
      return

    if $(e).hasClass 'target'
      component = e.value
      return

    if e.hasAttribute 'multiple'
      options = Array.from e.options
      payload[e.name] = options.map((x) -> x.value)
    else if e.hasAttribute 'data-list'
      payload[e.name] = [e.value]
    else
      payload[e.name] = e.value

  switch mode
    when 'admins[web][groups]'
      endpoint = window.endpoint.api.groups
    when 'admins[web][admins]'
      method = 'post'
      endpoint = window.endpoint.api.users[component]

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
