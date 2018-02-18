server = (query, that=null) ->
  $({'query': query}).ajax('/api/v1/servers', 'GET', (data, status) ->
    data = JSON.parse data
    data = data['result']

    if that != null
      formatted = [{'value': 'all', 'label': '<b>all</b>'}]
      for ele in data
        formatted.push {'value': ele.id, 'label': ele.name}
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

group = (query, that=null) ->
  $({'query': query}).ajax('/api/v1/roles', 'GET', (data, status) ->
    data = JSON.parse data
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        formatted.push {'value': ele.id, 'label': ele.name}
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

submit = (mode='', refresh=[]) ->
  switch mode
    when 'admin__administrator'
      data =
        role: window.groupinput.getValue(true)
        promotion: true
        force: true

      user = window.usernameinput.getValue(true)

      window.endpoint.users[user].post(data, (err, data) ->
        if data.success
          window.ajax.admin.admins(1)

        return data
      )
      console.log data
    when 'admin__groups'
      console.log 'stoff'
    else
      console.log 'stuff'

window.api =
  servers: server
  groups: group
  submit: submit
