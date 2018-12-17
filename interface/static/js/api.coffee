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

  return [validated, reason]

transform = (el) ->
  if not el.hasAttribute 'data-transform'
    return el.value

  transformation = el.getAttribute 'data-transform'
  if transformation is 'iso-duration'
    duration = new Duration(el.value)
    return duration.seconds

  if transformation is 'flatpickr'
    timestamp = $(el).parent('.flatpickr')[0]._flatpickr.selectedDates[0].getTime()
    timestamp = (timestamp / 1000) >> 0
    current = (new Date / 1000) >> 0
    return timestamp - current

  return el.value

window.api.utils =
  validation: validation
  transform: transform
