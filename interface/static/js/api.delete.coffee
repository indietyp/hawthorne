single = (mode = '', target) ->
  payload = {}
  options = {}
  node = target.parentElement.parentElement.parentElement

  switch mode
    when 'punishment'
      endpoint = window.endpoint.api.users[user].punishments[target.getAttribute('data-uuid')]

  endpoint.delete(options, {}, payload, (err, data) ->
    if data.success
      $(node).css('opacity', '0.5')
  )

remove = (mode = '', target, batch = false) ->
  if batch
    targets = window.batch
    window.batch = []
  else
    targets = [target]

  window.target.forEach((element) ->
    single(mode, element)
  )
  return

window.api.remove = remove
