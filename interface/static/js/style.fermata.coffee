fermata.registerPlugin 'hawpi', (transport, base) ->
  # I know the name is fcking clever
  @base = base

  (request, callback) ->
    # the rest is "borrowed" from the built-in JSON plugin
    request.headers['Accept'] = 'application/json'
    request.headers['Content-Type'] = 'application/json'
    request.data = JSON.stringify(request.data)

    transport request, (err, response) ->
      if not err
        if response.status.toFixed()[0] is not '2'
          err = Error('Bad status code from server: ' + response.status)
        try
          response = JSON.parse(response.data)
        catch e
          err = e

      callback err, response
      return
