#= require api.delete.coffee
#= require api.edit.coffee
#= require api.create.coffee

validation = (el) ->
  validated = true
  reason = ''
  if not el.value
    return validated

  if el.hasAttribute 'data-link'

    link = el.getAttribute 'data-link'
    form = $(el).parent 'form'
    reason = 'Only one field can be filled.'

    $("[data-link=#{link}]", form).not([el]).forEach (e) ->
      if e.value
        validated = false

  return validated

transform = (el) ->
  if not el.hasAttribute 'data-transform'
    return el.value

  transformation = el.getAttribute 'data-transform'
  if transformation is 'iso-duration'
    duration = new Duration(el.value)
    return duration.seconds

  return el.value

window.api.utils =
  validation: validation
  transform: transform
