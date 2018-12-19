#= require style.fermata.coffee
#= require style.ext.coffee
#= require style.time.coffee


copyTextToClipboard = (text) ->
  textArea = document.createElement('textarea')
  # https://stackoverflow.com/questions/400212/how-do-i-copy-to-the-clipboard-in-javascript
  textArea.style.position = 'fixed'
  textArea.style.top = 0
  textArea.style.left = 0

  textArea.style.width = '2em'
  textArea.style.height = '2em'
  textArea.style.padding = 0

  textArea.style.border = 'none'
  textArea.style.outline = 'none'
  textArea.style.boxShadow = 'none'

  textArea.style.background = 'transparent'
  textArea.value = text
  document.body.appendChild textArea
  textArea.focus()
  textArea.select()
  try
    successful = document.execCommand('copy')
    msg = if successful then 'successful' else 'unsuccessful'
  catch err
    console.log 'Oops, unable to copy'

  document.body.removeChild textArea
  return


executeServer = (that) ->
  parent = $(that.parentElement)
  id = $('.hidden', parent)[0].value

  removed = []
  parent[0].childNodes.forEach((element) ->
    if element.nodeName is '#text' or element.nodeName is 'BR'
      removed.push element
  )

  removed.forEach((element) ->
    parent[0].removeChild element
  )

  data =
    command: $('.command', parent)[0].value

  window.endpoint.api.servers[id].execute.put({}, {}, data, (err, response) ->
    output = response.result.response.split('\n')

    output.forEach((element, index) ->
      output[index] = "> #{element}"
    )

    output = output.join('<br />')
    parent.htmlPrepend(output)
  )
  return


loginUsername = (event) ->
  if event.target.value.length isnt 0
    $('.transition').slideDown()
  else
    $('.transition').slideUp()


showToast = (mode, message) ->
  toast = $ '.toast'
  toast.addClass mode

  description = $ '.desc', '.toast'
  description[0].innerHTML = message

  toast.addClass 'show'

  setTimeout(->
    toast.removeClass mode
    toast.removeClass 'show'
  , 5000)

  return

window.style.copy = copyTextToClipboard
window.style.rcon = executeServer
window.style.login = loginUsername
window.style.toast = showToast

window.endpoint =
  api: fermata.hawpi '/api/v1'
  ajax: fermata.raw {base: window.location.origin + '/ajax/v1'}
  bare: fermata.raw {base: window.location.origin}
