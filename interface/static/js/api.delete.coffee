single = (mode = '', target) ->
  payload = {}
  options = {}

  switch mode
    when 'punishment'
      uuid = target.getAttribute('data-id')
      user = target.getAttribute('data-user')
      endpoint = window.endpoint.api.users[user].punishments[uuid]

    when 'admins[server][admins]'
      uuid = target.getAttribute('data-id')
      user = target.getAttribute('data-user')
      endpoint = window.endpoint.api.users[user]

      payload =
        reset: true

    when 'admins[server][roles]'
      uuid = target.getAttribute('data-id')
      endpoint = window.endpoint.api.roles[uuid]

    when 'admins[web][admins]'
      id = target.getAttribute('data-id')
      user = target.getAttribute('data-user')
      endpoint = window.endpoint.api.users[user]

      payload =
        groups: [id]
        reset: false

    when 'admins[web][groups]'
      id = target.getAttribute('data-id')
      endpoint = window.endpoint.api.groups[id]

    when 'servers[detailed]'
      uuid = target.getAttribute('data-id')
      endpoint = window.endpoint.api.servers[uuid]

  endpoint.delete(options, {}, payload, (err, data) ->
    if data.success
      if target.hasAttribute('data-opacity')
        uuid = target.getAttribute('data-id')
        parent = $("[data-id='#{uuid}']").css('opacity', '0.5').removeClass('logSelected')
        $('.checkboxDialogue', parent).fadeOut 'fast'
        $('.checkmarkContainer', parent).css('visibility', 'hidden')

      if target.hasAttribute('data-remove')
        $(target).remove()

      if target.hasAttribute('data-visibility')
        $(target).css('visibility', 'hidden')

      if target.hasAttribute('data-redirect')
        window.vc()

    return
  )

remove = (mode = '', target, batch = false) ->
  if batch
    targets = window.batch
    window.batch = []
  else
    targets = [target]

  targets.forEach((element) ->
    single(mode, element)
  )
  return

window.api.remove = remove
