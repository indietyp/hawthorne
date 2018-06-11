$( ->
  #$(".menu").height($(document).outerHeight());
  $('[data-trigger=\'[dropdown/toggle]\']').on 'click', ->
    $('.expand').not($(this).parent().find('.expand')).slideUp()
    $('.menu > ul > li > a').not($(this)).removeClass 'navActive'
    $(this).toggleClass 'navActive'
    $(this).parent().find('.expand').slideToggle()
    return
  $('[data-trigger=\'[modal/open]\']').on 'click', ->
    $('.overlay').fadeIn 'fast'
    $('[data-component=\'' + $(this).attr('data-trigger-target') + '\']').fadeIn 'fast'
    return
  $('[data-trigger=\'[server/item]\']').on 'click', ->
    $(this).toggleClass 'toggableListActive'
    $(this).find('.content').fadeToggle 'fast'
    return
  $('[data-trigger=\'[modal/close]\']').on 'click', ->
    $('.overlay').fadeOut 'fast'
    $(this).parent().fadeOut 'fast'
    return
  $('.overlay').on 'click', ->
    $('.overlay').fadeOut 'fast'
    $('.modal').fadeOut 'fast'
    return
  $('[data-trigger=\'[system/messages/open]\']').on 'click', ->
    $(this).find('.notificationsArea').fadeToggle 'fast'
    $(this).find('a').first().toggleClass 'userMenuActive'
    return
  $('.searchOverlay').on 'click', ->
    $('.searchOverlay').fadeOut 'fast'
    $('.searchArea').fadeOut 'fast'
    $('.search').animate { width: '20%' }, 250
    return
  $('[data-trigger=\'[announcement/expand]\']').on 'click', ->
    $(this).find('.announcement-expand').slideToggle()
    return
  $('[data-trigger=\'[user/toggle]\']').on 'click', ->
    $(this).find('.dropdown').fadeToggle 'fast'
    return
  $('.search input').on 'click', ->
    $('.modal').fadeOut 'fast'
    $('.searchOverlay').fadeIn 'fast'
    $('.searchArea').fadeToggle 'fast'
    $('.search').animate { width: '30%' }, 250
    return
  return
)
