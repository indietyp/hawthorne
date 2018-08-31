ajax = (mode, target = '.main', page = 1, manual = false, action = 'append') ->
  endpoint = window.endpoint.ajax
  header =
    'X-CSRFToken': window.csrftoken

  switch mode
    when 'home[update]'
      endpoint = window.endpoint.ajax.system.update
    when 'servers[overview]'
      endpoint = window.endpoint.ajax.servers[page]
    when 'players[overview]'
      endpoint = window.endpoint.ajax.players[page]
    when 'admins[servers][admins]'
      endpoint = window.endpoint.ajax.admins.servers.admins[page]
    when 'admins[servers][roles]'
      endpoint = window.endpoint.ajax.admins.servers.roles[page]
    when 'admins[web][admins]'
      endpoint = window.endpoint.ajax.admins.web.admins[page]
    when 'admins[web][groups]'
      endpoint = window.endpoint.ajax.admins.web.groups[page]
    when 'punishments[bans]'
      endpoint = window.endpoint.ajax.punishments.bans[page]
    when 'punishments[mutes]'
      endpoint = window.endpoint.ajax.punishments.mutes[page]
    when 'punishments[gags]'
      endpoint = window.endpoint.ajax.punishments.gags[page]


  endpoint.post(header, {}, (dummy, response) ->
    data = response.data

    target = $(target)

    if response.status is 200
      if page is 1 or manual
        target.html('')

      switch action
        when 'append'
          target.htmlAppend(data)
        when 'prepend'
          target.htmlPrepend(data)
        when 'before'
          target.htmlBefore(data)
        when 'after'
          target.htmlAfter(data)

      $('script.execute:not(.evaluated)', target).forEach((src) ->
        eval(src.innerHTML)
        $(src).addClass 'evaluated'
      )
      window._.init(target)

      switch manual
        when true
          if page is 1
            $('.timeTableGo.fLeft').addClass 'hidden'
          else
            $('.timeTableGo.fLeft').removeClass 'hidden'

          if window.pagination.limitation is page
            $('.timeTableGo.fRight').addClass 'hidden'
          else
            $('.timeTableGo.fRight').removeClass 'hidden'

          $('.paginationContent h3 .current')[0].innerHTML = page
          window.pagination.current = page

          url = new URL(document.location.href)
          params = new URLSearchParams(url.search.substring(1))
          params.set('page', page)
          url.search = "?#{params.toString()}"

          history.pushState(null, null, url.href)
        when false
          window.ajax(mode, target, page + 1)

    return
  )

  return

lazy = (mode, fallback) ->
  endpoint = window.endpoint.ajax
  header =
    'X-CSRFToken': window.csrftoken

  if window.location.hash
    hash = window.location.hash.substring(1)
  else
    hash = fallback
    history.pushState(null, null, "##{fallback}")

  switch mode
    when 'servers[detailed]'
      endpoint = window.endpoint.ajax.servers[window.slug][hash]
    when 'admins[servers]'
      endpoint = window.endpoint.ajax.admins.servers[hash]
    when 'admins[web]'
      endpoint = window.endpoint.ajax.admins.web[hash]
    when 'players[overview]'
      endpoint = window.endpoint.ajax.players
    when 'players[detailed]'
      endpoint = window.endpoint.ajax.players[window.slug][hash]
    when 'punishments[bans]'
      endpoint = window.endpoint.ajax.punishments.bans
    when 'punishments[mutes]'
      endpoint = window.endpoint.ajax.punishments.mutes
    when 'punishments[gags]'
      endpoint = window.endpoint.ajax.punishments.gags

  a = new URLSearchParams(window.location.search.substring(1))
  endpoint.post(header, a, (dummy, response) ->
    status = response.status
    data = response.data
    target = $('.main')

    if status is 200
      $('.paginationContent', target).remove()
      target.htmlAppend(data)
      $('.paginationContent script.execute:not(.evaluated)', target).forEach((src) ->
        eval(src.innerHTML)
        $(src).addClass 'evaluated'
      )
    return
  )

  return

window.ajax = ajax
window.lazy = lazy
