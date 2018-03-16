submit = (mode='', that) ->
  o =
    target: that
    skip_animation: false

  switch mode
    when 'admin__administrator'
      data =
        role: window.groupinput.getValue(true)
        promotion: true
        force: true

      user = window.usernameinput.getValue(true)

      window.endpoint.api.users[user].post(data, (err, data) ->
        window.ajax.admin.admins(1)
        return data
      )

    when 'admin__groups'
      data =
        name: $("#inputgroupname").value
        server: window.serverinput.getValue(true)
        immunity: parseInt $("#inputimmunityvalue").value
        usetime: null
        flags: ''

      if data.server == 'all'
        data.server = null

      for i in $(".row.add .actions input:checked")
        data.flags += $(i).value

      time = $("#inputtimevalue").value
      if time is not null or time != ''
        data.usetime = window.style.duration.parse(time)

      window.endpoint.api.roles.put(o, {}, data, (err, data) ->
        window.ajax.ban.user(1)
        return data
      )

    when 'ban'
      now = new Date()
      now = now.getTime() / 1000

      time = $("#inputduration")[0].value

      if time != ''
        time = new Date $("#inputduration")[0].value
        time = time.getTime() / 1000
      else
        time = 0

      user = window.usernameinput.getValue(true)

      data =
        reason: $("#inputdescription")[0].value
        length: parseInt(time - now)

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.api.users[user].ban.put(o, {}, data, (err, data) ->
        window.ajax.ban.user(1)
      )

    when 'mutegag'
      now = new Date()
      now = now.getTime() / 1000

      time = $("#inputduration")[0].value

      if time != ''
        time = new Date time
        time = time.getTime() / 1000
      else
        time = 0

      user = window.usernameinput.getValue(true)

      type = ''
      $('.row.add .action .selected').forEach((e) ->
        type += e.id
      )

      if type.match(/mute/) and type.match(/gag/)
        type = 'both'

      if type == ''
        type = 'both'

      data =
        reason: $("#inputdescription")[0].value
        length: parseInt(time - now)
        type: type

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.api.users[user].mutegag.put(o, {}, data, (err, data) ->
        window.ajax.mutegag.user(1)
        return data
      )

    when 'kick'
      console.log 'placeholder'

    when 'server'
      node = that.parentElement.parentElement.parentElement

      data =
        name: $("#inputservername")[0].value
        ip: $('#inputip')[0].value.match(/^([0-9]{1,3}\.){3}[0-9]{1,3}/)[0]
        port: parseInt $('#inputip')[0].value.split(':')[1]
        password: $('#inputpassword')[0].value
        game: window.gameinput.getValue(true)
        mode: $('#inputmode')[0].value

      window.endpoint.api.servers.put(o, {}, data, (err, data) ->
        window.ajax.server.server(1)
        return data
      )

    when 'server__execute'
      node = that.parentElement.parentElement.parentElement.parentElement
      uuid = $('input.uuid', node)[0].value
      value = $('pre.input', node)[0].textContent

      payload =
        command: value

      $(that).addClass 'orange'
      output = $('pre.ro', node)
      output.css 'max-height', ''

      window.endpoint.api.servers[uuid].execute.put(payload, (err, data) ->
        if data.success
          $(that).addClass 'green'
          output.html data.result.response

          console.log output[0].innerHTML
          output[0].innerHTML = "<span class='line'>"+(output[0].textContent.split("\n").filter(Boolean).join("</span>\n<span class='line'>"))+"</span>";

          output.removeClass 'none'
          $('pre.input', node).addClass 'evaluated'
          output.css 'max-height', output[0].scrollHeight+'px'

        else
          $(that).addClass 'red'

        $(that).removeClass 'orange'
        return data
      )

      setTimeout(->
        $(that).removeClass 'red'
        $(that).removeClass 'green'
        $(that).addClass 'white'
      , 2500)

    else
      console.warning 'You little bastard! This is not implemented....'

window.api.submit = submit
