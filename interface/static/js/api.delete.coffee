single = (mode = '', target) ->
  payload = {}
  options = {}

  switch mode
    when 'punishment'
      uuid = target.getAttribute('data-id')
      user = target.getAttribute('data-user')
      endpoint = window.endpoint.api.users[user].punishments[uuid]

    when 'admins[web][admins]'
      uuid = target.getAttribute('data-id')
      user = target.getAttribute('data-user')
      endpoint = window.endpoint.api.users[user]

      payload =
        roles: [uuid]

  endpoint.delete(options, {}, payload, (err, data) ->
    if data.success
      if target.hasAttribute('data-opacity')
        uuid = target.getAttribute('data-id')
        parent = $("[data-id='#{uuid}']").css('opacity', '0.5').removeClass('logSelected')
        $('.checkboxDialogue', parent).fadeOut 'fast'
        $('.checkmarkContainer', parent).css('visibility', 'hidden')

      if target.hasAttribute('data-remove')
        $(target).remove()

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
  window.batch = []
  return

window.api.remove = remove
