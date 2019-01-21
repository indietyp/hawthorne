request = (endpoint, options, payload, method, target) ->
  endpoint[method](options, {}, payload, (err, data) ->
    if data.success
      target.reset()
  )


single = (mode = '', target) ->
  options =
    toast: true
  method = 'put'

  [payload, component, validated] = window.api.utils.normalize target

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
    when 'system[token]'
      endpoint = window.endpoint.api.system.tokens

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
