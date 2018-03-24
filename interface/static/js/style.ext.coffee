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

$.fn.hasClass = (className) ->
  return !!this[ 0 ] && this[ 0 ].classList.contains( className )

$.fn.addClass = (className) ->
  @forEach((item) ->
    classList = item.classList
    classList.add.apply(classList, className.split( /\s/ ))
  )
  this

$.fn.removeClass = (className) ->
  @forEach((item) ->
    classList = item.classList
    classList.remove.apply(classList, className.split( /\s/ ))
  )
  this

$.fn.toggleClass = (className, b) ->
  @forEach (item) ->
    classList = item.classList
    if typeof b != 'boolean'
      b = !classList.contains(className)

    classList[if b then 'add' else 'remove'].apply classList, className.split(/\s/)
    return
  this

$.fn.css = (property, value=null) ->
  if value == null
    console.log 'this is not yet implemented'
  else
    @forEach((item) ->
      try
        item.style[property] = value
      catch e
        console.error 'Could not set css style property "' + property + '".'
    )
  this

$.fn.remove = () ->
  @forEach((item) ->
    item.parentNode.removeChild item
  )
  this

$.fn.val = (value='') ->
  if value != ''
    @forEach((item) ->
      item.value = value
    )

  else if this[0]
    return this[0].value
  this

$.fn.html = (value=null) ->
  if value != null
    @forEach((item) ->
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
