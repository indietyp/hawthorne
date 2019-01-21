#= require api.delete.coffee
#= require api.edit.coffee
#= require api.create.coffee

validation = (el) ->
  validated = true
  reason = ''
  if not el.value
    return [validated, reason]

  if el.hasAttribute 'data-link'
    link = el.getAttribute 'data-link'
    form = $(el).parent 'form'
    reason = 'Only one field can be filled.'

    $("[data-link=#{link}]", form).not([el]).forEach (e) ->
      if e.value
        validated = false

  if not validated
    window.style.toast('error', 'Invalid value detected!')

  return [validated, reason]


transform = (el) ->
  if not el.hasAttribute 'data-transform'
    return el.value

  transformation = el.getAttribute 'data-transform'
  if transformation is 'iso-duration'
    duration = new Duration(el.value)
    return duration.seconds

  if transformation is 'ip-port'
    return el.value.split(':').splice(0, 2)

  if transformation is 'flatpickr'
    timestamp = $(el).parent('.flatpickr')[0]._flatpickr.selectedDates[0].getTime()
    timestamp = (timestamp / 1000) >> 0
    current = (new Date / 1000) >> 0
    return timestamp - current

  if transformation is 'flatpickr-timestamp'
    timestamp = $(el).parent('.flatpickr')[0]._flatpickr.selectedDates[0].getTime()
    timestamp = (timestamp / 1000) >> 0

    return timestamp

  if transformation is 'lower'
    return el.value.toLowerCase()

  return el.value


normalize = (form) ->
  payload = {}
  validated = true
  component = undefined

  Array.from(form.elements).forEach (e) ->
    if $(e).hasClass 'skip'
      return

    value = window.api.utils.transform e
    valid = window.api.utils.validation e

    if not valid[0]
      validated = false
      $(e).addClass 'invalid'
      console.log valid
      $('span span.invalid', $(e).parent())[0].innerHTML = valid[1]

      return

    if $(e).hasClass 'target'
      component = value
      return

    name = e.name
    if e.hasAttribute 'data-name'
      name = e.getAttribute 'data-name'

    if e.hasAttribute 'multiple'
      options = Array.from e.options
      payload[name] = options.map((x) -> x.value)
    else if e.hasAttribute('data-boolean')
      payload[e.getAttribute('data-boolean')] = e.checked
    else if e.getAttribute('type') is 'checkbox'
      if not e.checked
        return
      if not payload.hasOwnProperty e.name
        payload[name] = []
      payload[name].push value
    else if e.hasAttribute 'data-list'
      payload[name] = [value]
    else if name.includes('/') and value.constructor.name == 'Array'
      values = []
      names = name.split('/')
      for i in [0..names.length] by 1
        values.push [names[i], value[i]]

      values.forEach (v) ->
        payload[v[0]] = v[1]
    else if value
      payload[name] = value

  return [payload, component, validated]

window.api.utils =
  validation: validation
  transform: transform
  normalize: normalize
