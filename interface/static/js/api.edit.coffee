save = (mode = '', that) ->
  o =
    target: that
    skip_animation: false

  node = that.parentElement.parentElement.parentElement

  switch mode
    when 'admin__administrator'
      role = $('input.role', node)[0].value
      uuid = $('input.uuid', node)[0].value

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
        window.endpoint.api.users[uuid].post(payload, (err, data) ->
          if (!data.success)
            return

          success += 1
        )

      target = $(that)
      if success == 2
        target.addClass 'explicit red'
      else
        target.addClass 'explicit green'

      setTimeout(->
        target.removeClass 'explicit green red'
      , 1200)

    when 'admin__groups'
      uuid = $("input.uuid", node)[0].value

      data =
        name: $(".name span", node).html()
        server: window.api.storage[uuid].getValue(true)
        immunity: parseInt $(".immunity span", node).html().match(/([0-9]|[1-8][0-9]|9[0-9]|100)(?:%)?$/)[1]
        usetime: -1
        flags: ''

      $(".immunity span", node).html("#{data.immunity}%")
      if data.server == 'all'
        data.server = null

      $(".actions input:checked", node).forEach((i) ->
        data.flags += i.value
      )

      time = $(".usetime span", node).html()
      if time is not null or time != ''
        data.usetime = window.style.duration.parse(time)

      window.endpoint.api.roles[uuid].post(o, {}, data, (err, data) ->)

    when 'mutegag', 'ban'
      user = $('input.user', node)[0].value
      server = $('input.server', node)[0].value
      punishment = $('input.punishment', node)[0].value

      now = parseInt($(".icon.time", node)[0].getAttribute("data-created"))
      time = $(".icon.time input", node)[0].value

      if time != ''
        time = new Date time
        time = time.getTime() / 1000
      else
        time = 0

      payload =
        length: parseInt(time - now)
        reason: $(".icon.reason span", node).html()

      if server != ''
        payload.server = server

      if mode == 'ban'
        payload.banned = true

      if mode == 'mutegag'
        $('.icon.modes .red', node).forEach((e) ->
          payload.type += e.getAttribute 'data-type'
        )

        payload.muted = false
        payload.gagged = false
        if payload.type.match(/mute/) and payload.type.match(/gag/)
          payload.muted = true
          payload.gagged = true

        if payload.type == ''
          payload.muted = true
          payload.gagged = true

        if type.match /mute/
          payload.muted = true

        if type.match /gag/
          payload.gagged = true

      window.endpoint.api.users[user].punishments[punishment].post(o, {}, payload, (err, data) ->)

    when 'server'
      node = node.parentElement
      uuid = $('input.uuid', node)[0].value
      selector = window.api.storage[uuid]

      payload =
        game: selector.getValue(true)
        gamemode: $(".icon.gamemode span", node).html()
        ip: $(".icon.network span", node).html().split(':')[0]
        port: parseInt $(".icon.network span", node).html().split(':')[1]

      password = $(".icon.password input", node)[0].value
      if password != ''
        payload.password = password

      window.endpoint.api.servers[uuid].post(o, {}, payload, (err, data) ->)

    when 'setting__user'
      uuid = $('input.uuid', node)[0].value
      selector = window.api.storage[uuid]

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
        groups: selector.getValue(true)

      window.endpoint.api.users[uuid].post(o, {}, payload, (err, data) ->)

    when 'setting__group'
      uuid = $('input.uuid', node)[0].value
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

      window.endpoint.api.groups[uuid].post(o, {}, payload, (err, data) ->)

  return

edit = (mode = '', that) ->
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

      uuid = $('input.uuid', node)[0].value
      selected = $('input.role', node)[0].value
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
        target = $('.server span', node)
        server = selector.getValue().customProperties.server
        if server == null
          target.html 'all'
        else
          window.endpoint.api.servers[server].get((err, data) ->
            if not data.success
              return
            target.html data.result.name
          )

      , false)

      window.api.storage[uuid + '#' + selected] = selector
      window.api.roles('', selector, selected)

    when 'admin__groups'
      server = node.querySelector('.icon.server')

      uuid = $('input.uuid', node)[0].value
      selected = $('input.server', node)[0].value

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

      $('.icon.group .actions', node).removeClass('disabled').addClass('enabled')
      $(".icon.usetime", node).addClass('input-wrapper')
      $(".icon.usetime span i", node).remove()
      $(".icon.usetime span", node).on('focusout', (event, ui) ->
        field = $(@)
        sd = field.html()
        seconds = window.style.duration.parse(sd)

        if sd != '' and seconds == 0
          field.css 'border-bottom-color', '#FF404B'
        else
          field.css 'border-bottom-color', ''
          field.html window.style.duration.string(seconds)
      )

      $(".icon.immunity", node).addClass('input-wrapper')
      $(".icon.name", node).addClass('input-wrapper')

      $(".icon span", node).addClass('input')
      $(".icon span", node).forEach((el) ->
        el.setAttribute 'contenteditable', 'true'
      )

      window.api.storage[uuid] = selector
      window.api.servers('', selector, selected)

    when 'ban', 'mutegag'
      $(".icon.reason", node).addClass('input-wrapper')
      $(".icon.reason span", node).addClass('input')
      $(".icon.reason span", node)[0].setAttribute('contenteditable', 'true')

      $(".icon.time", node).addClass('input-wrapper')
      timestamp = parseInt($(".icon.time span", node)[0].getAttribute('data-timestamp')) * 1000

      date = new Date timestamp
      date = window.style.utils.date.convert.to.iso(date)

      now = window.style.utils.date.convert.to.iso(new Date())

      $(".icon.time", node).htmlAppend("<input type='datetime-local' min='#{now}' value='#{date}'>")
      $(".icon.time span", node).remove()

      $(".icon.modes div", node).addClass('action').forEach((el) ->
        el.setAttribute 'onclick', 'window.style.mutegag.toggle(this)'
      )

      $(".icon.modes div svg", node).forEach((el) ->
        el = $(el)
        if el.hasClass('gray')
          el.removeClass('gray').addClass('red')

        if el.hasClass('white')
          el.removeClass('white').addClass('gray')
      )

    when 'server'
      node = node.parentElement
      uuid = $('input.uuid', node)[0].value

      games = $(".icon.game", node)
      $('span', games[0]).remove()
      games.htmlAppend("<select id='server-#{uuid}'></select>")
      selector = new Choices("#server-#{uuid}", {
        searchEnabled: false,
        choices: [],
        classNames: {
          containerOuter: 'choices edit big'
        }
      })
      window.api.games(selector, games[0].getAttribute('data-value'))

      $(".icon.gamemode", node).addClass('input-wrapper big')
      $(".icon.gamemode span", node).addClass('input')
      $(".icon.gamemode span", node)[0].setAttribute('contenteditable', 'true')

      $(".icon.network", node).addClass('input-wrapper big')
      $(".icon.network span", node).addClass('input')
      $(".icon.network span", node)[0].setAttribute('contenteditable', 'true')

      $(".icon.password", node).addClass('input-wrapper big')
      $(".icon.password", node).htmlAppend('<input type="password", placeholder="Password"></input>')
      $(".icon.password span", node).remove()

      window.api.storage[uuid] = selector

    when 'setting__user'
      $('.column.animated', node).toggleClass('collapsed')
      uuid = $('input.uuid', node)[0].value
      roles = $('.column.groups', node)

      roles.htmlAppend("<select id='user-group-#{uuid}' multiple></select>")
      selector = new Choices("#user-group-#{uuid}", {
        choices: [],
        duplicateItems: false,
        paste: false,
        searchEnabled: false,
        searchChoices: false,
        removeItemButton: true,
        classNames: {
          containerOuter: 'choices edit'
        }
      })
      window.api.groups('', selector, $('span', roles).html().split(', '))
      $('span', roles).remove()

      window.style.settings.init(true)
      window.api.storage[uuid] = selector

    when 'setting__group'
      $('.column.animated', node).toggleClass('collapsed')
      window.style.settings.init(true)

  $(that).css('opacity', '0')
  setTimeout(->
    $(that).htmlAfter("<i class='save opacity animated' data-feather='save'></i>")
    feather.replace()

    transition = that.parentElement.querySelector('.save.opacity.animated')
    $(that).remove()

    # we need this timeout so that the transition can be applied properly
    # i know this is not the perfect way, but it is still better than twilight
    setTimeout(->
      transition.setAttribute 'onclick', trigger
      $(transition).css('opacity', '1')
    , 300)
  , 300)
  return

window.api.edit = edit
