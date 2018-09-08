$(->
  init()
)

init = (scope = document) ->
  dropdown_toggle = (event) ->
    event.stopImmediatePropagation()

    $('.expand').not($('.expand', @.parentElement)).slideUp()
    $('.menu > ul > li > a').not($(@)).removeClass 'navActive'
    $(@).toggleClass 'navActive'
    $('.expand', @.parentElement).slideToggle()

    return
  $('[data-trigger=\'[dropdown/toggle]\']', scope).on 'click', dropdown_toggle


  modal_open = ->
    $('.overlay').fadeIn 'fast'
    $('[data-component=\'' + @.getAttribute('data-trigger-target') + '\']').fadeIn 'fast'
    return
  $('[data-trigger=\'[modal/open]\']', scope).on 'click', modal_open

  server_item = ->
    $(@).toggleClass 'toggableListActive'
    $(@).find('.content').fadeToggle 'fast'
    return
  $('[data-trigger=\'[server/item]\']', scope).on 'click', server_item


  modal_close = ->
    $('.overlay').fadeOut 'fast'
    $(@.parentElement).fadeOut 'fast'
    return
  $('[data-trigger=\'[modal/close]\']', scope).on 'click', modal_close


  overlay = ->
    $('.overlay').fadeOut 'fast'
    $('.modal').fadeOut 'fast'
    return
  $('.overlay', scope).on 'click', overlay


  system_messages_open = ->
    $('.notificationsArea', @).fadeToggle 'fast'
    $($('a', @)[0]).toggleClass 'userMenuActive'
    return
  $('[data-trigger=\'[system/messages/open]\']', scope).on 'click', system_messages_open

  search_overlay = ->
    $('.searchOverlay').fadeOut 'fast'
    $('.searchArea').fadeOut 'fast'
    $('.search').animate {width: '20%'}, 250
    return
  $('.searchOverlay', scope).on 'click', search_overlay


  announcement_expand = ->
    $(@).find('.announcement-expand').slideToggle()
    return
  $('[data-trigger=\'[announcement/expand]\']', scope).on 'click', announcement_expand


  user_toggle = ->
    $(@).find('.dropdown').fadeToggle 'fast'
    return
  $('[data-trigger=\'[user/toggle]\']', scope).on 'click', user_toggle


  search_input = ->
    $('.modal').fadeOut 'fast'
    $('.searchOverlay').fadeIn 'fast'
    $('.searchArea').fadeToggle 'fast'
    $('.search').animate {width: '30%'}, 250
    return
  $('.search input', scope).on 'click', search_input


  checkmark_toggle = ->
    $(@.parentElement.parentElement).toggleClass 'logSelected'
    $('.checkboxDialogue').not($('.checkboxDialogue', @.parentElement)).fadeOut 'fast'

    if not $('input', @)[0].checked
      $('.checkboxDialogue', @.parentElement).fadeIn 'fast'
    else
      $('.checkboxDialogue', @.parentElement).fadeOut 'fast'

    return
  $('.timeTable tbody tr td .checkmarkContainer', scope).on 'mousedown', checkmark_toggle


  # retired
  $('[data-trigger=\'[modal/system/log/import/input/add]\']', scope).on 'click', ->
    $(@).parent().find('.appendInput').append '<input type=\'text\' placeholder=\'/home/server/addons/sourcemod/logs/error.log\' class=\'mbotSmall\'>'
    return


  composer_select_open = ->
    $(@).parent('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(@).parent('._Dynamic_Select').find('._Select').toggle()
    $(@).parent('._Dynamic_Select').find('._Select').find('._Select_Search').find('input').focus()
    return
  $('[data-trigger=\'[composer/select/open]\']', scope).on 'click', composer_select_open


  selectionData = []
  composer_select_choose = ->
    if $(@).parent().closest('._Dynamic_Select').find('._Title').attr('data-select-multiple') == 'true'
      text = $(@).find('p').text()
      checkBox = $(@).find('.checkmarkContainer input')
      if not checkBox.is(':checked')
        checkBox.prop 'checked', true
        selectionData.push text
      else
        checkBox.prop 'checked', false
        i = 0
        while i < selectionData.length
          if selectionData[i] is text
            selectionData.splice i, 1
            break
          i += 1
      $(@).closest('._Dynamic_Select').find('._Title').text '(' + selectionData.length + ') selections'
      return
    $(@).closest('._Dynamic_Select').find('._Title').text $(@).find('b').text()
    $(@).closest('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(@).closest('._Select').hide()
    return
  $('[data-trigger=\'[composer/select/choose]\']', scope).on 'click', composer_select_choose

  ct_switch = ->
    $('.paginationTabSelected', @.parentElement).removeClass('paginationTabSelected')
    hash = @.getAttribute('data')
    $(@).addClass('paginationTabSelected')

    history.replaceState({'location': window._.location, 'scope': window._.scope}, null, "##{hash}")
    window.lazy(@.parentElement.getAttribute('data-target'), '')
    return
  $('[data-trigger=\'[ct/switch]\']', scope).on 'click', ct_switch


  clipboard = (event) ->
    window.style.copy(@.getAttribute('data-clipboard-text'))
  $('[data-trigger="[clip/copy]"]', scope).on 'click', clipboard

  return

menu = ->
  $('.paginationTabs').forEach((i) ->
    for e in i.children
      if window.location.hash and window.location.hash.substring(1) is e.getAttribute('data')
        $(e).addClass('paginationTabSelected')
  )
  return

window._ =
  init: init
  menu: menu
