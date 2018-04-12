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

      console.log $('input.user', node)[0]
      console.log user

      payload =
        server: server

      endpoint = window.endpoint.api.users[user].ban
    when 'mutegag'
      user = $('input.user', node)[0].value
      server = $('input.server', node)[0].value

      if server != ''
        payload =
          server: server

      endpoint = window.endpoint.api.users[user].mutegag
    when 'server'
      node = that.parentElement.parentElement.parentElement.parentElement
      server = $('input.uuid', node)[0].value

      endpoint = window.endpoint.api.servers[server]

    when 'setting__user'
      console.log 'test'

    when 'setting__group'
      console.log 'test'

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
