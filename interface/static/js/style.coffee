insertHtml = (value, position, nodes) ->
  nodes.forEach((item) ->
    tmpnodes = document.createElement('div')
    tmpnodes.innerHTML = value
    while (tmpnode = tmpnodes.lastChild) != null
      try
        if position == 'before'
          item.parentNode.insertBefore tmpnode, item
        else if position == 'after'
          item.parentNode.insertBefore tmpnode, item.nextSibling
        else if position == 'append'
          item.appendChild tmpnode
        else if position == 'prepend'
          item.insertBefore tmpnode, item.firstChild
      catch e
        break
  )

# original code from davesag
# http://jsfiddle.net/davesag/qgCrk/6/
to_seconds = (dd, hh, mm) ->
  d = parseInt(dd)
  h = parseInt(hh)
  m = parseInt(mm)
  d ?= 0
  h ?= 0
  m ?= 0
  # if (isNaN(d)) d = 0
  # if (isNaN(h)) h = 0
  # if (isNaN(m)) m = 0

  t = d * 24 * 60 * 60 +
      h * 60 * 60 +
      m * 60
  return t

# expects 1d 11h 11m, or 1d 11h,
# or 11h 11m, or 11h, or 11m, or 1d
# returns a number of seconds.
parseDuration = (sDuration) ->
  if sDuration == null or sDuration == ''
    return 0

  mrx = new RegExp(/([0-9][0-9]?)[ ]?m(?:[^o]|$)/)
  hrx = new RegExp(/([0-9][0-9]?)[ ]?h/)
  drx = new RegExp(/([0-9]{1,2})[ ]?d/)
  wrx = new RegExp(/([0-9][0-9]?)[ ]?w/)
  morx = new RegExp(/([0-9][0-9]?)[ ]?mo/)
  yrx = new RegExp(/([0-9][0-9]?)[ ]?y/)

  days = 0
  hours = 0
  minutes = 0
  if morx.test(sDuration)
    days += morx.exec(sDuration)[1]*31
  if mrx.test(sDuration)
    minutes = mrx.exec(sDuration)[1]
  if hrx.test(sDuration)
    hours = hrx.exec(sDuration)[1]
  if drx.test(sDuration)
    days += drx.exec(sDuration)[1]
  if wrx.test(sDuration)
    days += wrx.exec(sDuration)[1]*7
  if yrx.test(sDuration)
    days += yrx.exec(sDuration)[1]*365

  return to_seconds(days, hours, minutes)

# outputs a duration string based on
# the number of seconds provided.
# rounded off to the nearest 1 minute.
toDurationString = (iDuration) ->
  if iDuration <= 0
    return ''

  m = Math.floor((iDuration/60)%60)
  h = Math.floor((iDuration/3600)%24)
  d = Math.floor(iDuration/86400)
  result = ''
  if d > 0
    result = result + d + 'd '
  if h > 0
    result = result + h + 'h '
  if m > 0
    result = result + m + 'm '
  return result.substring(0, result.length - 1)

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

DatetoISO8601 = (obj) ->
  year = obj.getFullYear()
  month = if obj.getMonth().toString().length == 1 then '0' + (obj.getMonth() + 1).toString() else obj.getMonth() + 1
  date = if obj.getDate().toString().length == 1 then '0' + obj.getDate().toString() else obj.getDate()
  hours = if obj.getHours().toString().length == 1 then '0' + obj.getHours().toString() else obj.getHours()
  minutes = if obj.getMinutes().toString().length == 1 then '0' + obj.getMinutes().toString() else obj.getMinutes()

  "#{year}-#{month}-#{date}T#{hours}:#{minutes}"

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


submit = (that, success=true, cleanup=false) ->
  state = that.getAttribute 'class'

  if not state.match /animated/
    return false

  if success and not state.match /success/
    state += ' success explicit green'

  if not success and not state.match /fail/
    state += ' fail explicit red'

  if cleanup
    state = state.replace /explicit/g, ''
    state = state.replace /green/g, ''
    state = state.replace /red/g, ''
    state = state.replace /fail/g, ''
    state = state.replace /success/g, ''
    state = state.replace /(\s+)/g, ' '

  that.setAttribute 'class', state

window.style =
  duration:
    parse: parseDuration
    string: toDurationString

  mutegag:
    toggle: mutegag__toggle

  submit: submit

  utils:
    date:
      convert:
        to:
          iso: DatetoISO8601

    verify:
      input: InputVerification

$(() ->

)

$.fn.hasClass = (className) ->
  return !!this[ 0 ] && this[ 0 ].classList.contains( className )

$.fn.addClass = (className) ->
  this.forEach((item) ->
    classList = item.classList
    classList.add.apply(classList, className.split( /\s/ ))
  )
  this

$.fn.removeClass = (className) ->
  this.forEach((item) ->
    classList = item.classList
    classList.remove.apply(classList, className.split( /\s/ ))
  )
  this

$.fn.toggleClass = (className, b) ->
  this.forEach((item) ->
    classList = item.classList;
    if (typeof b != 'boolean')
      b = !classList.contains( className )
    classList[ b ? 'add' : 'remove' ].apply(classList, className.split( /\s/ ))
  )
  this

$.fn.css = (property, value=null) ->
  if value == null
    console.log 'this is not yet implemented'
  else
    this.forEach((item) ->
      try
        item.style[property] = value
      catch e
        console.error 'Could not set css style property "' + property + '".'
    )
  this

$.fn.remove = () ->
  this.forEach((item) ->
    item.parentNode.removeChild item
  )
  this

$.fn.val = (value='') ->
  if value != ''
    this.forEach((item) ->
      item.value = value
    )

  else if this[0]
    return this[0].value
  this

$.fn.html = (value='') ->
  if value != ''
    this.forEach((item) ->
      item.innerHTML = value
    )

  if this[0]
    return this[0].innerHTML
  this

$.fn.htmlBefore = (value) ->
  insertHtml value, 'before', this
  this

$.fn.htmlAfter = (value) ->
  insertHtml value, 'after', this
  this

$.fn.htmlAppend = (value) ->
  insertHtml value, 'append', this
  this

$.fn.htmlPrepend = (value) ->
  insertHtml value, 'prepend', this
  this

window.cache = {}

window.endpoint =
  api: fermata.json "/api/v1"
  ajax: fermata.raw {base:window.location.origin + "/ajax/v1"}
  bare: fermata.raw {base:window.location.origin}
