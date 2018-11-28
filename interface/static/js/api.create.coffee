single = (mode = '', target) ->
  payload = {}
  options = {}

  Array.from(target.elements).forEach (e) ->
    if $(e).hasClass 'skip'
      return

    if e.hasAttribute 'multiple'
      options = Array.from e.options
      payload[e.name] = options.map((x) -> x.value)
    else
      payload[e.name] = e.value

  console.log payload

  switch mode
    when 'admins[web][groups]'
      endpoint = window.endpoint.api.groups

  endpoint.put(options, {}, payload, (err, data) ->
    if data['success']
      target.reset()

  )
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
