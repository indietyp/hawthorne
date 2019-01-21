single = (mode = '', target, overwrite) ->
  options =
    toast: true
  method = 'post'

  [payload, component, validated] = window.api.util.normalize target

  if overwrite
    component = overwrite

  if not validated
    return

  switch mode
    when 'admins[web][groups]'
      endpoint = window.endpoint.api.groups[component]
    when 'admins[server][roles]'
      endpoint = window.endpoint.api.roles[component]
    when 'players[detailed][punishment]'
      endpoint = window.endpoint.api.users[component].punishments
    when 'servers'
      endpoint = window.endpoint.api.servers[component]


  endpoint[method](options, {}, payload, (err, data) ->
    if data.success
      target.reset()
  )

  return

edit = (mode = '', target, batch = false) ->
  if batch
    window.batch.forEach (value) ->
      single(mode, target, value.getAttribute('data-id'))
    window.batch = []
  else
    single(mode, target)

  return

window.api.edit = edit
