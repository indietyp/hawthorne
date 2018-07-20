ajax = (mode, target='.main', page=1) ->
  endpoint = window.endpoint.ajax
  header =
    "X-CSRFToken": window.csrftoken

  switch mode
    when "servers[overview]"
      endpoint = window.endpoint.ajax.servers[page]

  endpoint.post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    target = $(target)

    if status == 200
      if page == 1
        target.html('')

      target.htmlAppend(data)
      $('script.execute:not(.evaluated)', target).forEach((src) ->
        eval(src.innerHTML)
        $(src).addClass("evaluated")
      )

      window.ajax(mode, target, page + 1)
    return
  )

  return

lazy = (mode, fallback) ->
  endpoint = window.endpoint.ajax
  header =
    "X-CSRFToken": window.csrftoken

  if window.location.hash
    hash = window.location.hash.substring(1)
  else
    hash = fallback
    history.pushState(null, null, "##{fallback}");

  switch mode
    when "servers[detailed]"
      endpoint = window.endpoint.ajax.servers[window.slug][hash]

  endpoint.post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data
    target = $('.main')

    if status == 200

      $('.paginationContent', target).remove()
      target.htmlAppend(data)
      $('script.execute:not(.evaluated)', target).forEach((src) ->
        eval(src.innerHTML)
        $(src).addClass("evaluated")
      )
    return
  )

  return

window.ajax = ajax
window.lazy = lazy
