# view controller

load = (destination='home', scope='') ->
  endpoint = window.endpoint.bare

  switch destination
    when 'home'
      url = ""
    when 'servers'
      url = "servers"
    when 'servers[detailed]'
      url = "servers/#{scope}"
    else
      return

  header =
    'X-CSRFTOKEN': window.csrftoken

  window.endpoint.bare[url].post(header, {}, (dummy, response) ->
    status = response.status
    data = response.data

    if status == 200
      $(".main")[0].innerHTML = data
      $(".main script.execute").forEach((scr) ->
        eval(scr.innerHTML)
      )

      url = if not url then '/' else url
      window.history.pushState "", "", url
  )

window.vc = load
