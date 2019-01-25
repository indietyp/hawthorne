single = (mode = '', target, overwrite) ->
  options =
    toast: true
  method = 'post'

  [payload, component, validated] = window.api.utils.normalize target

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
      [c0, c1] =  component.split(':')
      endpoint = window.endpoint.api.users[c0].punishments[c1]
    when 'servers'
      endpoint = window.endpoint.api.servers[component]

  endpoint[method](options, {}, payload, (err, data) ->
    return
  )

  return

edit = (mode = '', target, batch = false) ->
  if batch
    window.batch.forEach (e) ->
      single(mode, target, e.getAttribute('data-overwrite'))

  else
    single(mode, target)

  return

window.api.edit = edit
