submit = (mode = '', that) ->
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
        name: $("#inputgroupname")[0].value
        server: window.serverinput.getValue(true)
        immunity: parseInt $("#inputimmunityvalue")[0].value
        usetime: null
        flags: ''

      if data.server == 'all'
        data.server = null

      $(".row.add .actions input:checked").forEach((i) ->
        data.flags += i.value
      )

      time = $("#inputtimevalue")[0].value
      if time is not null or time != ''
        data.usetime = window.style.duration.parse(time)

      window.endpoint.api.roles.put(o, {}, data, (err, data) ->
        window.ajax.admin.groups(1)
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
        banned: true

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.api.users[user].punishments.put(o, {}, data, (err, data) ->
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

      mute = false
      gag = false
      if type.match(/mute/) and type.match(/gag/)
        mute = true
        gag = true

      if type == ''
        mute = true
        gag = true

      if type.match /mute/
        mute = true

      if type.match /gag/
        gag = true

      data =
        reason: $("#inputdescription")[0].value
        length: parseInt(time - now)
        type: type
        muted: mute
        gagged: gag

      server = window.serverinput.getValue(true)
      if server != 'all'
        data.server = server

      window.endpoint.api.users[user].punishments.put(o, {}, data, (err, data) ->
        window.ajax.mutegag.user(1)
        return data
      )

    when 'kick'
      user = $('input.uuid', node)[0].value
      data =
        server: $('input.server', node)[0].value
        kicked: true

      window.endpoint.api.users[user].punishments.put(o, {}, data, (err, data) ->
        window.ajax.player.user(1)
        return data
      )

    when 'server'
      node = that.parentElement.parentElement.parentElement

      data =
        name: $("#inputservername")[0].value
        ip: $('#inputip')[0].value.split(':')[0]
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
          output[0].innerHTML = "<span class='line'>" + (output[0].textContent.split("\n").filter(Boolean).join("</span>\n<span class='line'>")) + "</span>";

          output.removeClass 'none'
          $('pre.input', node).addClass 'evaluated'
          output.css 'max-height', output[0].scrollHeight + 'px'

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

    when 'setting__user'
      node = that.parentElement.parentElement.parentElement
      perms = []

      $('.permission__child:checked', node).forEach((i) ->
        cl = i.id
        cl = cl.replace /\s/g, ''

        cl = cl.split '__'
        cl = "#{cl[0]}.#{cl[1]}"

        perms.push cl
      )

      if $(".scope__toggle", node).hasClass 'activated'
        local = true
      else
        local = false

      payload =
        permissions: perms
        internal: true
        local: local
        groups: window.groupinput.getValue(true)

      if not local
        payload.steamid = window.usernameinput.getValue(true)
      else
        payload.email = $("#inputemail", node)[0].value

      window.endpoint.api.users.put(o, {}, payload, (err, data) ->
        window.ajax.setting.user(1)
        return data
      )

    when 'setting__group'
      node = that.parentElement.parentElement.parentElement
      perms = []

      $('.permission__child:checked', node).forEach((i) ->
        cl = i.id
        cl = cl.replace /\s/g, ''

        cl = cl.split '__'
        cl = "#{cl[0]}.#{cl[1]}"

        perms.push cl
      )

      payload =
        name: $("#inputgroupname", node)[0].value
        permissions: perms
        members: []

      window.endpoint.api.groups.put(o, {}, payload, (err, data) ->
        window.ajax.setting.group(1)
        return data
      )

    when 'setting__token'
      node = that.parentElement.parentElement.parentElement
      perms = []

      $('.permission__child:checked', node).forEach((i) ->
        cl = i.id
        cl = cl.replace /\s/g, ''

        cl = cl.split '__'
        cl = "#{cl[0]}.#{cl[1]}"

        perms.push cl
      )

      payload =
        permissions: perms
        due: null
        active: true

      window.endpoint.api.system.tokens.put(o, {}, payload, (err, data) ->
        window.ajax.setting.token(1)
        return data
      )

    when 'mainframe'
      node = that.parentElement.parentElement.parentElement
      window.endpoint.api.mainframe.connect.put(o, {}, {}, (err, data) ->
        $('.description.info-container').html("<span class='green'> Connected </span><span class='prefix primary'>#{data.result.id}</span>")
        $('.action-container').css('display', 'none')
      )


    else
      console.warning 'You little bastard! This is not implemented....'

window.api.submit = submit
