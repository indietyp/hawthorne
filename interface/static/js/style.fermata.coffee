fermata.registerPlugin 'hawpi', (transport, base) ->
# I know the name is fcking clever
  @base = base

  (request, callback) ->
# the rest is "borrowed" from the built-in JSON plugin
    request.headers['Accept'] = 'application/json'
    request.headers['Content-Type'] = 'application/json'
    request.data = JSON.stringify(request.data)

    transport request, (err, response) ->
      if !err
        if response.status.toFixed()[0] != '2'
          err = Error('Bad status code from server: ' + response.status)
        try
          response = JSON.parse(response.data)
        catch e
          err = e

      target = request.options.target
      skip = request.options.skip_animation
      if target
        if !err and not skip
          window.style.submit.state(target, true)

        if err and not skip
          window.style.submit.state(target, false)

        if err or not response.success
          window.style.card(true, response.reason)

      callback err, response

      if request.options.target
        setTimeout(->
          window.style.submit.clear(target)

          if err
            window.style.card(false)
        , 2400)

      return
