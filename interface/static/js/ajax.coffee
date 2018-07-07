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
      $('script.execute', target).forEach((src) ->
        eval(src.innerHTML)
      )

      window.ajax(mode, target, page + 1)
    return
  )

  return

window.ajax = ajax
