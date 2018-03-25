# first add raf shim
# http://www.paulirish.com/2011/requestanimationframe-for-smart-animating/
# main function

scrollToY = (scrollTargetY, speed, easing) ->
  # scrollTargetY: the target scrollY property of the window
  # speed: time in pixels per second
  # easing: easing equation to use
  scrollY = window.scrollY
  scrollTargetY = scrollTargetY or 0
  speed = speed or 2000
  easing = easing or 'easeOutSine'
  currentTime = 0

  # min time .1, max time .8 seconds
  time = Math.max(.1, Math.min(Math.abs(scrollY - scrollTargetY) / speed, .8))
  # easing equations from https://github.com/danro/easing-js/blob/master/easing.js
  PI_D2 = Math.PI / 2
  easingEquations =
    easeOutSine: (pos) ->
      Math.sin pos * Math.PI / 2
    easeInOutSine: (pos) ->
      -0.5 * (Math.cos(Math.PI * pos) - 1)
    easeInOutQuint: (pos) ->
      if (pos /= 0.5) < 1
        return 0.5 * pos ** 5
      0.5 * ((pos - 2) ** 5 + 2)
  # call it once to get started
  # add animation loop

  tick = ->
    currentTime += 1 / 60
    p = currentTime / time
    t = easingEquations[easing](p)
    if p < 1
      requestAnimFrame tick
      window.scrollTo 0, scrollY + (scrollTargetY - scrollY) * t
    else
      window.scrollTo 0, scrollTargetY
    return

  tick()
  return

scrollToYPages = (page = 1) ->
  scrollToY document.getElementsByClassName('section')[0].scrollHeight * (page - 1), 1500, 'easeInOutQuint'
  return

window.requestAnimFrame = do ->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60
    return

window.scrollToYPages = scrollToYPages
