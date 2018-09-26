insertHtml = (value, position, nodes) ->
  nodes.forEach((item) ->
    if value.includes '<td'
      tmpnodes = document.createElement('tbody')
    else
      tmpnodes = document.createElement('div')
    tmpnodes.innerHTML = value

    while (tmpnode = tmpnodes.lastChild) isnt null
      try
        if position is 'before'
          item.parentNode.insertBefore tmpnode, item
        else if position is 'after'
          item.parentNode.insertBefore tmpnode, item.nextSibling
        else if position is 'append'
          item.appendChild tmpnode
        else if position is 'prepend'
          item.insertBefore tmpnode, item.firstChild
      catch e
        break
  )

$.fn.hasClass = (className) ->
  # might need !! i dunno
  return not not @[0] and @[0].classList.contains(className)

$.fn.addClass = (className) ->
  @forEach((item) ->
    classList = item.classList
    classList.add.apply(classList, className.split(/\s/))
  )
  @

$.fn.removeClass = (className) ->
  @forEach((item) ->
    classList = item.classList
    classList.remove.apply(classList, className.split(/\s/))
  )
  @

$.fn.toggleClass = (className, b) ->
  @forEach (item) ->
    classList = item.classList
    if typeof b isnt 'boolean'
      b = not classList.contains(className)

    classList[if b then 'add' else 'remove'].apply classList, className.split(/\s/)
    return
  @

$.fn.css = (property, value = null) ->
  if value is null
    console.log 'this is not yet implemented'
  else
    @forEach((item) ->
      try
        item.style[property] = value
      catch e
        console.error 'Could not set css style property "' + property + '".'
    )
  @

$.fn.remove = ->
  @forEach((item) ->
    item.parentNode.removeChild item
  )
  @

$.fn.val = (value = '') ->
  if value isnt ''
    @forEach((item) ->
      item.value = value
    )

  else if @[0]
    return @[0].value
  @

$.fn.html = (value = null) ->
  if value isnt null
    @forEach((item) ->
      item.innerHTML = value
    )

  if @[0]
    return @[0].innerHTML
  @

$.fn.htmlBefore = (value) ->
  insertHtml value, 'before', @
  @

$.fn.htmlAfter = (value) ->
  insertHtml value, 'after', @
  @

$.fn.htmlAppend = (value) ->
  insertHtml value, 'append', @
  @

$.fn.htmlPrepend = (value) ->
  insertHtml value, 'prepend', @
  @

$.fn.fadeIn = (value) ->
  @forEach((item) ->
    item.style.display = 'block'
    item.style.opacity = '0'
    item.style.transition = '0.2s opacity ease'

    setTimeout(->
      item.style.opacity = null
    , 10)
  )
  @

$.fn.fadeOut = (value) ->
  @forEach((item) ->
    item.style.transition = '0.2s opacity ease'
    item.style.opacity = '0'
    setTimeout(->
      item.style.display = 'none'
    , 200)
  )
  @


$.fn.fadeToggle = (value) ->
  @forEach((item) ->
    item.style.transition = '0.2s opacity ease'

    if window.getComputedStyle(item).display is 'none'
      item.style.display = 'block'
      setTimeout(->
        item.style.opacity = null
      , 10)
    else
      item.style.opacity = '0'
      setTimeout(->
        item.style.display = 'none'
      , 200)
  )
  @

$.fn.not = (value) ->
  $(@filter((item) -> item not in value))

getHeight = (el) ->
  el_style = window.getComputedStyle(el)
  el_display = el_style.display
  el_position = el_style.position
  el_visibility = el_style.visibility
  el_max_height = el_style.maxHeight.replace('px', '').replace('%', '')
  wanted_height = 0
  # if its not hidden we just return normal height
  if el_display isnt 'none' and el_max_height isnt '0'
    return el.offsetHeight
  # the element is hidden so:
  # making the el block so we can meassure its height but still be hidden
  el.style.position = 'absolute'
  el.style.visibility = 'hidden'
  el.style.display = 'block'
  wanted_height = el.offsetHeight
  # reverting to the original values
  el.style.display = el_display
  el.style.position = el_position
  el.style.visibility = el_visibility
  wanted_height

$.fn.slideToggle = ->
  @forEach((el) ->
    el_max_height = 0
    if el.getAttribute('data-max-height')
      # we've already used this before, so everything is setup
      setTimeout (->
        if el.style.maxHeight.replace('px', '').replace('%', '') is '0'
          el.style.display = 'block'

          setTimeout (->
            el.style.maxHeight = el.getAttribute('data-max-height')
          ), 10
        else
          el.style.maxHeight = '0'

          setTimeout (->
            el.style.display = 'none'
          ), 500

        return
      ), 10
    else
      el_max_height = getHeight(el) + 'px'
      el.style.transition = 'max-height 0.5s ease-in-out'
      el.style.overflowY = 'hidden'
      el.setAttribute 'data-max-height', el_max_height
      el.style.display = 'block'
      el.style.maxHeight = '0'

      # we use setTimeout to modify maxHeight later than display
      setTimeout (->
        el.style.maxHeight = el_max_height
        return
      ), 10
  )
  @

$.fn.slideUp = ->
  if @.length is 0
    return

  style = window.getComputedStyle(@[0])
  if style.display isnt 'none'
    if not @[0].getAttribute('data-max-height')
      @[0].style.overflowY = 'hidden'
      @[0].style.maxHeight = style.height
      @[0].style.transition = 'max-height 0.5s ease-in-out'
      @[0].setAttribute 'data-max-height', style.height

    @slideToggle()

$.fn.slideDown = ->
  if @.length is 0
    return

  if window.getComputedStyle(@[0]).display is 'none'
    @slideToggle()

$.fn.animate = (values, timing) ->
  animation = ''

  for property in Object.entries(values)
    property[0] = if property[0] is 'width' then 'max-width' else property[0]
    animation += "#{property[0]} "
  animation += "#{timing / 1000}s ease"

  current = 0
  @forEach((item) ->
    item.style.transition = animation
    if Object.keys(values).includes('width')
      current = parseInt(item.style['max-width'])
      item.style['max-width'] = window.getComputedStyle(item).width
  )

  that = @
  setTimeout(->
    that.forEach((item) ->
      for property in Object.entries(values)
        if property[0] is 'width'
          item.style['max-width'] = property[1]

          if parseInt(property[1]) < current
            setTimeout(->
              item.style[property[0]] = property[1]
            , timing)
          else
            item.style[property[0]] = property[1]

        else
          item.style[property[0]] = property[1]
    )
  , 10)

  @
