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

submit = (mode='', that) ->
  switch mode
    when 'admin__administrator'
      data =
        role: window.groupinput.getValue(true)
        promotion: true
        force: true

      user = window.usernameinput.getValue(true)

      window.endpoint.users[user].post(data, (err, data) ->
        if data.success
          window.style.submit(that)
        else
          window.style.submit(that, false)

        return data
      )

      setTimeout(->
        window.style.submit(that, false, true)
        window.ajax.admin.admins(1)
      , 3000)

    when 'admin__groups'
      data =
        name: $("#inputgroupname").val()
        server: window.serverinput.getValue(true)
        immunity: parseInt $("#inputimmunityvalue").val()
        usetime: null
        flags: ''

      if data.server == 'all'
        data.server = null

      for i in $(".row.add .actions input:checked")
        data.flags += $(i).val()

      time = $("#inputtimevalue").val()
      if time is not null or time != ''
        data.usetime = window.style.duration.parse(time)

      window.endpoint.roles.put(data, (err, data) ->
        if data.success
          window.style.submit(that)
        else
          window.style.submit(that, false)

        return data
      )

      setTimeout(->
        window.style.submit(that, false, true)
        window.ajax.ban.user(1)
      , 3000)

    when 'ban'
      now = new Date()
      now = now.getTime() / 1000

      time = $("#inputduration").val()

      if time != ''
        time = new Date $("#inputduration").val()
        time = time.getTime() / 1000
      else
        time = 0

      user = window.usernameinput.getValue(true)

      data =
        reason: $("#inputdescription").val()
        length: parseInt(time - now)

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.users[user].ban.put(data, (err, data) ->
        if data.success
          window.style.submit(that)
        else
          window.style.submit(that, false)
      )

      setTimeout(->
        window.style.submit(that, false, true)
        window.ajax.ban.user(1)
      , 3000)

    when 'mutegag'
      now = new Date()
      now = now.getTime() / 1000

      time = $("#inputduration").val()

      if time != ''
        time = new Date time
        time = time.getTime() / 1000
      else
        time = 0

      user = window.usernameinput.getValue(true)

      type = ''
      $('.row.add .action .selected').each ((e) ->
        type += e.id
      )

      if type.match(/mute/) and type.match(/gag/)
        type = 'both'

      if type == ''
        type = 'both'

      data =
        reason: $("#inputdescription").val()
        length: parseInt(time - now)
        type: type

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.users[user].mutegag.put(data, (err, data) ->
        if data.success
          window.style.submit(that)
        else
          window.style.submit(that, false)

        return data
      )

      setTimeout(->
        window.style.submit(that, false, true)
        window.ajax.mutegag.user(1)
      , 3000)

    when 'kick'
      console.log 'placeholder'
    when 'server'
      console.log 'placeholder'
    else
      console.log 'stuff'

window.api =
  servers: server
  groups: group
  submit: submit
