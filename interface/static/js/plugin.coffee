$( ->
  #$(".menu").height($(document).outerHeight());
  $('[data-trigger=\'[dropdown/toggle]\']').on 'click', ->
    $('.expand').not($('.expand', this.parentElement)).slideUp()
    $('.menu > ul > li > a').not($(this)).removeClass 'navActive'
    $(this).toggleClass 'navActive'
    $('.expand', this.parentElement).slideToggle()
    return

  $('[data-trigger=\'[modal/open]\']').on 'click', ->
    $('.overlay').fadeIn 'fast'
    $('[data-component=\'' + this.getAttribute('data-trigger-target') + '\']').fadeIn 'fast'
    return

  $('[data-trigger=\'[server/item]\']').on 'click', ->
    $(this).toggleClass 'toggableListActive'
    $(this).find('.content').fadeToggle 'fast'
    return

  $('[data-trigger=\'[modal/close]\']').on 'click', ->
    $('.overlay').fadeOut 'fast'
    $(this.parentElement).fadeOut 'fast'
    return

  $('.overlay').on 'click', ->
    $('.overlay').fadeOut 'fast'
    $('.modal').fadeOut 'fast'
    return

  $('[data-trigger=\'[system/messages/open]\']').on 'click', ->
    $('.notificationsArea', this).fadeToggle 'fast'
    $($('a', this)[0]).toggleClass 'userMenuActive'
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

  $('.timeTable tbody tr td .checkmarkContainer').on 'mousedown', ->
    $(this).closest('tr').toggleClass 'logSelected'
    $('.checkboxDialogue').not($(this).parent().find('.checkboxDialogue')).fadeOut 'fast'
    if !$(this).find('input').prop('checked')
      $(this).parent().find('.checkboxDialogue').fadeIn 'fast'
    else
      $(this).parent().find('.checkboxDialogue').fadeOut 'fast'
    return

  $('[data-trigger=\'[modal/system/log/import/input/add]\']').on 'click', ->
    $(this).parent().find('.appendInput').append '<input type=\'text\' placeholder=\'/home/server/addons/sourcemod/logs/error.log\' class=\'mbotSmall\'>'
    return

  $('[data-trigger=\'[composer/select/open]\']').on 'click', ->
    $(this).parent('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(this).parent('._Dynamic_Select').find('._Select').toggle()
    $(this).parent('._Dynamic_Select').find('._Select').find('._Select_Search').find('input').focus()
    return

  $('[data-trigger=\'[composer/select/choose]\']').on 'click', ->
    $(this).closest('._Dynamic_Select').find('._Title').text $(this).find('b').text()
    $(this).closest('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(this).closest('._Select').hide()
    return

  new ClipboardJS('[data-trigger="[clip/copy]"]')
  return
)
