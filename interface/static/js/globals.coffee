Object::getOrCreate = (prop) ->
  if @[prop] is undefined
    @[prop] = {}
  @[prop]

String.prototype.toTitleCase = ->
  return @.replace(/\w\S*/g, (txt) ->
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
  )

window.style = {}
window.cache = {}
window.api =
  storage: {}
