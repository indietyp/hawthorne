$(->
  init()
)

init = (scope=document) ->
  dropdown_toggle = (event) ->
    event.stopImmediatePropagation()

    $('.expand').not($('.expand', this.parentElement)).slideUp()
    $('.menu > ul > li > a').not($(this)).removeClass 'navActive'
    $(this).toggleClass 'navActive'
    $('.expand', this.parentElement).slideToggle()

    return
  $('[data-trigger=\'[dropdown/toggle]\']', scope).on 'click', dropdown_toggle


  modal_open = ->
    $('.overlay').fadeIn 'fast'
    $('[data-component=\'' + this.getAttribute('data-trigger-target') + '\']').fadeIn 'fast'
    return
  $('[data-trigger=\'[modal/open]\']', scope).on 'click', modal_open

  server_item = ->
    $(this).toggleClass 'toggableListActive'
    $(this).find('.content').fadeToggle 'fast'
    return
  $('[data-trigger=\'[server/item]\']', scope).on 'click', server_item


  modal_close = ->
    $('.overlay').fadeOut 'fast'
    $(this.parentElement).fadeOut 'fast'
    return
  $('[data-trigger=\'[modal/close]\']', scope).on 'click', modal_close


  overlay = ->
    $('.overlay').fadeOut 'fast'
    $('.modal').fadeOut 'fast'
    return
  $('.overlay', scope).on 'click', overlay


  system_messages_open = ->
    $('.notificationsArea', this).fadeToggle 'fast'
    $($('a', this)[0]).toggleClass 'userMenuActive'
    return
  $('[data-trigger=\'[system/messages/open]\']', scope).on 'click', system_messages_open

  search_overlay = ->
    $('.searchOverlay').fadeOut 'fast'
    $('.searchArea').fadeOut 'fast'
    $('.search').animate { width: '20%' }, 250
    return
  $('.searchOverlay', scope).on 'click', search_overlay


  announcement_expand = ->
    $(this).find('.announcement-expand').slideToggle()
    return
  $('[data-trigger=\'[announcement/expand]\']', scope).on 'click', announcement_expand


  user_toggle = ->
    $(this).find('.dropdown').fadeToggle 'fast'
    return
  $('[data-trigger=\'[user/toggle]\']', scope).on 'click', user_toggle


  search_input = ->
    $('.modal').fadeOut 'fast'
    $('.searchOverlay').fadeIn 'fast'
    $('.searchArea').fadeToggle 'fast'
    $('.search').animate { width: '30%' }, 250
    return
  $('.search input', scope).on 'click', search_input


  checkmark_toggle = ->
    $(this.parentElement.parentElement).toggleClass 'logSelected'
    $('.checkboxDialogue').not($('.checkboxDialogue', this.parentElement)).fadeOut 'fast'

    if not $('input', this)[0].checked
      $('.checkboxDialogue', this.parentElement).fadeIn 'fast'
    else
      $('.checkboxDialogue', this.parentElement).fadeOut 'fast'

    return
  $('.timeTable tbody tr td .checkmarkContainer', scope).on 'mousedown', checkmark_toggle


  # retired
  $('[data-trigger=\'[modal/system/log/import/input/add]\']', scope).on 'click', ->
    $(this).parent().find('.appendInput').append '<input type=\'text\' placeholder=\'/home/server/addons/sourcemod/logs/error.log\' class=\'mbotSmall\'>'
    return


  composer_select_open = ->
    $(this).parent('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(this).parent('._Dynamic_Select').find('._Select').toggle()
    $(this).parent('._Dynamic_Select').find('._Select').find('._Select_Search').find('input').focus()
    return
  $('[data-trigger=\'[composer/select/open]\']', scope).on 'click', composer_select_open


  selectionData = []
  composer_select_choose = ->
    if $(this).parent().closest('._Dynamic_Select').find('._Title').attr('data-select-multiple') == 'true'
      text = $(this).find('p').text()
      checkBox = $(this).find('.checkmarkContainer input')
      if !checkBox.is(':checked')
        checkBox.prop 'checked', true
        selectionData.push text
      else
        checkBox.prop 'checked', false
        i = 0
        while i < selectionData.length
          if selectionData[i] == text
            selectionData.splice i, 1
            break
          i++
      $(this).closest('._Dynamic_Select').find('._Title').text '(' + selectionData.length + ') selections'
      return
    $(this).closest('._Dynamic_Select').find('._Title').text $(this).find('b').text()
    $(this).closest('._Dynamic_Select').toggleClass '_Dynamic_Select_Activated'
    $(this).closest('._Select').hide()
    return
  $('[data-trigger=\'[composer/select/choose]\']', scope).on 'click', composer_select_choose

  ct_switch = ->
    $('.paginationTabSelected', this.parentElement).removeClass('paginationTabSelected')
    hash = this.getAttribute('data')
    $(this).addClass('paginationTabSelected')

    history.pushState(null, null, "##{hash}");
    window.lazy(this.parentElement.getAttribute('data-target'), '')
    return
  $('[data-trigger=\'[ct/switch]\']', scope).on 'click', ct_switch


  clipboard = (event) ->
    window.style.copy(event.target.textContent)
  $('[data-trigger="[clip/copy]"]', scope).on 'click', clipboard

  return

menu = ->
  $('.paginationTabs').forEach((i) ->
    for e in i.children
      if window.location.hash and window.location.hash.substring(1) == e.getAttribute('data')
        $(e).addClass('paginationTabSelected')
  )
  return

window._ =
  init: init
  menu: menu
