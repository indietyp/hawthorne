remove = (mode = '', that) ->
  trans = $(that)

  if not trans.hasClass 'confirmation'
    trans.addClass 'explicit red confirmation'
    return

  payload = {}
  node = that.parentElement.parentElement.parentElement

  switch mode
    when 'admin__administrator'
      user = $('input.uuid', node)[0].value
      role = $('input.role', node)[0].value

      payload =
        reset: true
        role: role

      endpoint = window.endpoint.api.users[user]
    when 'admin__groups'
      role = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.roles[role]
    when 'ban'
      user = $('input.user', node)[0].value
      server = $('input.server', node)[0].value
      punishment = $('input.punishment', node)[0].value

      endpoint = window.endpoint.api.users[user].punishment[punishment]
    when 'mutegag'
      user = $('input.user', node)[0].value
      punishment = $('input.punishment', node)[0].value

      endpoint = window.endpoint.api.users[user].punishment[punishment]
    when 'server'
      node = that.parentElement.parentElement.parentElement.parentElement
      server = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.servers[server]

    when 'setting__user'
      uuid = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.users[uuid]

    when 'setting__group'
      uuid = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.groups[uuid]

    when 'setting__token'
      token = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.system.tokens[token]
    else
      console.warning 'mode not implemented'
      return

  options =
    target: that
    skip_animation: true

  endpoint.delete(options, {}, payload, (err, data) ->
    if data.success
      $(node).remove()
  )
  return

window.api.remove = remove
