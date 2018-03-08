`
var cssPath = function(el) {
    if (!(el instanceof Element)) return;
    var path = [];
    while (el.nodeType === Node.ELEMENT_NODE) {
        if (el.nodeName.toLowerCase() === 'body') {
          return path.join(" > ");
        }

        var selector = el.nodeName.toLowerCase();
        if (el.id) {
            selector += '#' + el.id;
        } else {
            var sib = el, nth = 1;
            while (sib.nodeType === Node.ELEMENT_NODE && (sib = sib.previousSibling) && nth++);
            selector += ":nth-child("+nth+")";
        }
        path.unshift(selector);
        el = el.parentNode;
    }
    return path.join(" > ");
}
`

server = (query, that=null, selected='') ->
  $({'query': query}).ajax('/api/v1/servers', 'GET', (data, status) ->
    data = JSON.parse data
    data = data['result']

    if that != null
      formatted = [{'value': 'all', 'label': '<b>all</b>'}]

      if selected == 'all'
        formatted[0].selected = true

      for ele in data
        fmt =
          value: ele.id
          label: ele.name

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

group = (query, that=null, selected='') ->
  $({'query': query}).ajax('/api/v1/roles', 'GET', (data, status) ->
    data = JSON.parse data
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        fmt =
          value: ele.id
          label: ele.name
          customProperties:
            server: ele.server

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

remove = (mode='', that) ->
  state = that.getAttribute 'class'

  if not state.match /confirmation/
    state += ' explicit red confirmation'
    that.setAttribute 'class', state
    return

  payload = {}
  node = that.parentElement.parentElement.parentElement

  switch mode
    when 'admin__administrator'
      user = $(node.querySelector('input.uuid')).val()
      role = $(node.querySelector('input.role')).val()

      payload =
        reset: true
        role: role

      endpoint = window.endpoint.users[user]
    when 'admin__groups'
      role = $(node.querySelector('input.uuid')).val()

      endpoint = window.endpoint.roles[role]
    when 'ban'
      user = $(node.querySelector('input.user')).val()
      server = $(node.querySelector('input.server')).val()

      payload =
        server: server

      endpoint = window.endpoint.users[user].ban
    when 'mutegag'
      user = $(node.querySelector('input.user')).val()
      server = $(node.querySelector('input.server')).val()

      if server != ''
        payload =
          server: server

      endpoint = window.endpoint.users[user].mutegag
    when 'server'
      node = that.parentElement.parentElement.parentElement.parentElement
      server = $(node.querySelector('input.uuid')).val()

      endpoint = window.endpoint.servers[server]
    else
      return

  endpoint.delete(payload, (err, data) ->
    if data.success
      $(node).remove()
  )
  return

save = (mode='', that) ->
  node = that.parentElement.parentElement.parentElement

  switch mode
    when 'admin__administrator'
      role = $(node.querySelector('input.role')).val()
      uuid = $(node.querySelector('input.uuid')).val()

      selector = window.api.storage[uuid + '#' + role]
      replacement = selector.getValue(true)

      payloads = [
        payload =
          promotion: false
          role: role
        payload =
          promotion: true
          role: replacement
      ]

      success = 0
      for payload in payloads
        window.endpoint.users[uuid].post(payload, (err, data) ->
          if (!data.success)
            return

          success += 1
        )

      state = that.getAttribute 'class'
      old = state

      if success == 2
        state += ' explicit red'
      else
        state += ' explicit green'
      that.setAttribute 'class', state

      setTimeout(->
        that.setAttribute 'class', old
      , 1200)

    when 'admin__groups'
      scope = cssPath node

      uuid = $("#{scope} input.uuid").val()
      console.log uuid

      data =
        name: $("#{scope} .name span").html()
        server: window.api.storage[uuid].getValue(true)
        immunity: parseInt $("#{scope} .immunity span").html().match(/([0-9]|[1-8][0-9]|9[0-9]|100)(?:%)?$/)[1]
        usetime: -1
        flags: ''

      $("#{scope} .immunity span").html("#{data.immunity}%")
      if data.server == 'all'
        data.server = null

      for i in $("#{scope} .actions input:checked")
        data.flags += $(i).val()

      time = $("#{scope} .usetime span").html()
      if time is not null or time != ''
        data.usetime = window.style.duration.parse(time)

      window.endpoint.roles[uuid].post(data, (err, data) ->
        state = that.getAttribute 'class'
        old = state

        if data.success
          state += ' explicit green'
        else
          state += ' explicit red'
        that.setAttribute 'class', state

        setTimeout(->
          that.setAttribute 'class', old
        , 1200)

        return data
      )

    when 'ban'
      console.log 'placeholder'

    when 'mutegag'
      console.log 'placeholder'

    when 'server'
      console.log 'placeholder'

  return

edit = (mode='', that) ->
  if that.getAttribute('class').match /save/
    # this is for the actual process of saving
    save mode, that
    return

  node = that.parentElement.parentElement.parentElement
  trigger = that.getAttribute 'onclick'

  # this is for converting the style to be editable.
  switch mode
    when 'admin__administrator'
      group = node.querySelector('.icon.group')

      uuid = $(node.querySelector('input.uuid')).val()
      selected = $(node.querySelector('input.role')).val()
      target = group.querySelector('span')
      $(target).remove()

      $(group).htmlAppend("<select id='group-#{uuid + '---' + selected}'></select>")
      selector = new Choices("#group-#{uuid + '---' + selected}", {
        searchEnabled: false,
        choices: [],
        classNames: {
          containerOuter: 'choices edit'
        }
      })

      selector.passedElement.addEventListener('change', (e) ->
        target = $(node.querySelector('.server span'))
        server = selector.getValue().customProperties.server
        if server == null
          target.html 'all'
        else
          window.endpoint.servers[server].get((err, data) ->
            if not data.success
              return
            target.html data.result.name
          )

      , false)

      window.api.storage[uuid + '#' + selected] = selector
      window.api.groups('', selector, selected)

    when 'admin__groups'
      server = node.querySelector('.icon.server')

      uuid = $(node.querySelector('input.uuid')).val()
      selected = $(node.querySelector('input.server')).val()

      if selected == ''
        selected = 'all'

      target = server.querySelector('span')
      $(target).remove()

      $(server).htmlAppend("<select id='server-#{uuid}'></select>")
      selector = new Choices("#server-#{uuid}", {
        searchEnabled: false,
        choices: [],
        classNames: {
          containerOuter: 'choices edit small'
        }
      })

      actions = node.querySelector('.icon.group .actions')
      $(actions).removeClass('disabled').addClass('enabled')

      scope = cssPath node

      $(scope + " .icon.usetime").addClass('input-wrapper')
      $(scope + " .icon.usetime span i").remove()
      $(scope + " .icon.usetime span").on('focusout', (event, ui) ->
        field = $(this)
        sd = field.html()
        seconds = window.style.duration.parse(sd)

        if sd != '' and seconds == 0
          field.css 'border-bottom-color', '#FF404B'
        else
          field.css 'border-bottom-color', ''
          field.html window.style.duration.string(seconds)
      )

      $(scope + " .icon.immunity").addClass('input-wrapper')
      $(scope + " .icon.name").addClass('input-wrapper')

      $(scope + " .icon span").addClass('input')
      $(scope + " .icon span").attr('contenteditable', 'true')

      window.api.storage[uuid] = selector
      window.api.servers('', selector, selected)

  $(that).css('opacity', '0')
  setTimeout(->
    $(that).htmlAfter("<i class='save opacity animated' data-feather='save'></i>")
    feather.replace()

    transition = that.parentElement.querySelector('.save.opacity.animated')
    $(that).remove()

    # we need this timeout so that the transition can be applied properly
    # i know this is not the perfect way, but it is still better than twilight
    setTimeout( ->
      transition.setAttribute 'onclick', trigger
      $(transition).css('opacity', '1')
    , 300)
  , 300)
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
      node = that.parentElement.parentElement.parentElement

      data =
        name: $("#inputservername").val()
        ip: $('#inputip').val().match(/^([0-9]{1,3}\.){3}[0-9]{1,3}/)[0]
        port: parseInt $('#inputip').val().split(':')[1]
        password: $('#inputpassword').val()
        game: window.gameinput.getValue(true)
        mode: $('#inputmode').val()

      window.endpoint.servers.put(data, (err, data) ->
        if data.success
          window.style.submit(that)
        else
          window.style.submit(that, false)

        return data
      )

      setTimeout(->
        window.style.submit(that, false, true)
        window.ajax.server.server(1)
      , 3000)
    else
      console.log 'stuff'

window.api =
  servers: server
  groups: group
  submit: submit
  remove: remove
  edit: edit
  storage: {}
