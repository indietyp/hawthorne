Object::getOrCreate = (prop) ->
  if @[prop] == undefined
    @[prop] = {}
  @[prop]

window.style = {}
window.cache = {}
window.api =
  storage: {}
