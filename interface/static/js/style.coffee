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

permission__toggle = (that) ->
  parent = that.parentElement

  $('.perms .permission.collapsed', parent).removeClass('collapsed').addClass('previous')
  $('.perms .permission:not(.previous)', parent).addClass 'collapsed'

  $('.perms .permission.previous', parent).removeClass 'previous'
  $('svg', that).toggleClass 'activated'

  if $('svg', that).hasClass 'activated'
    $('span', that).html('Advanced')
  else
    $('span', that).html('Simple')
  return

type__toggle = (that) ->
  parent = that.parentElement
  target = $('.column.username', parent)

  toggle = $('.choices', target).hasClass 'focus'
  if toggle
    $('.choices', target).removeClass 'focus'
  else
    $('.input-wrapper', target).removeClass 'focus'

  setTimeout(->
    if toggle
      $('.input-wrapper', target).addClass 'focus'
    else
      $('.choices', target).addClass 'focus'
    300)

  $('svg', that).toggleClass 'activated'

  if $('svg', that).hasClass 'activated'
    $('span', that).html('Local')
  else
    $('span', that).html('Steam')

settings__init = () ->
  $('.permission__child').on('change', (event) ->
    t = event.target

    cl = t.classList.value
    cl = cl.replace 'permission__child', ''
    cl = cl.replace /\s/g, ''

    candidates = $(".#{cl}")
    l = candidates.length
    i = 0

    candidates.forEach((item) ->
      if item.checked
        i++
    )

    if i == l
      $("##{cl}")[0].checked = true
    else if i == 0
      $("##{cl}")[0].checked = false
    else
      $("##{cl}")[0].checked = false
      $("##{cl} + label svg").addClass 'partially'

    if i in [l, 0]
      $("##{cl} + label svg").removeClass 'partially'
  )

  $('.permission__parent').on('change', (event) ->
    t = event.target

    $('label svg', t.parentElement).removeClass 'partially'
    if t.checked
      $(".permission__child.#{t.id}").forEach((i) -> i.checked = true)
    else
      $(".permission__child.#{t.id}").forEach((i) -> i.checked = false)
  )
  return

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


InformationCard = (show = true, reason) ->
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


submit__state = (that, success = true) ->
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
window.style.settings =
  permissions: permission__toggle
  type: type__toggle
  init: settings__init

window.style.submit =
  state: submit__state
  clear: submit__cleanup
window.style.card = InformationCard
window.style.copy = copyTextToClipboard


window.endpoint =
  api: fermata.hawpi "/api/v1"
  ajax: fermata.raw {base: window.location.origin + "/ajax/v1"}
  bare: fermata.raw {base: window.location.origin}
