#= require style.fermata.coffee
#= require style.ext.coffee
#= require style.time.coffee

mutegag__toggle = (that) ->
  for i in that.children
    state = i.getAttribute 'class'
    if state.match /gray/
      state = state.replace 'gray', ''
      state += 'red selected'
    else
      state = state.replace 'red', ''
      state = state.replace 'selected', ''
      state += 'gray'

    state = state.replace '  ', ' '
    i.setAttribute 'class', state

InputVerification = (mode, event, that) ->
  keycode = undefined
  if window.event
    keycode = window.event.keyCode
  else if event
    keycode = event.which

  character = String.fromCharCode(event.keyCode)
  switch mode
    when 'single'
      if keycode == 13
        return false

  return true


InformationCard = (show=true, reason) ->
  if show
    output = ''
    reason.forEach((i) ->
      if typeof i == 'string'
        output += "<div class='content'>#{i}</div>"
      else if typeof i == 'object'
        Object.keys(i).forEach((k) ->
          i[k].forEach((state) ->
            state = state.replace /of uuid type/g, 'present'
            state = state.replace /value/g, i[k]

            if state.search k == -1
              state = "#{k} #{state}"

            output += "<div class='content'>#{state}</div>"
          )
        )
    )
    $('.status-card .info').html output
    $('.status-card').addClass 'active'

  else
    $('.status-card').removeClass 'active'


submit__state = (that, success=true) ->
  target = $(that)
  animated = false

  if target.hasClass 'fancy'
    animated = true

  if success and not target.hasClass 'success'
    target.addClass 'explicit green'
    if animated
      target.addClass 'success'

  if not success and not target.hasClass 'fail'
    target.addClass 'explicit red'

    if animated
      target.addClass 'fail'

submit__cleanup = (that) ->
  state = that.getAttribute 'class'

  state = state.replace /explicit/g, ''
  state = state.replace /green/g, ''
  state = state.replace /red/g, ''
  state = state.replace /fail/g, ''
  state = state.replace /success/g, ''
  state = state.replace /(\s+)/g, ' '

  that.setAttribute 'class', state

window.style.getOrCreate('utils').getOrCreate('verify').input = InputVerification
window.style.getOrCreate('mutegag').toggle = mutegag__toggle
window.style.submit =
  state: submit__state
  clear: submit__cleanup
window.style.card = InformationCard


window.endpoint =
  api: fermata.hawpi "/api/v1"
  ajax: fermata.raw {base:window.location.origin + "/ajax/v1"}
  bare: fermata.raw {base:window.location.origin}
