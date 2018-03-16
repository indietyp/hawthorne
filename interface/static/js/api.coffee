#= require api.delete.coffee
#= require api.edit.coffee
#= require api.create.coffee


server = (query, that=null, selected='') ->
  window.endpoint.api.servers({'query': query}).get((err, data) ->
    data = data.result

    if that != null
      formatted = [{'value': 'all', 'label': '<b>all</b>'}]

      if selected == 'all'
        formatted[0].selected = true

      for ele in data
        fmt =
          value: ele.id
          label: ele.name

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

group = (query, that=null, selected='') ->
  window.endpoint.api.roles({'query': query}).get((err, data) ->
    data = data['result']

    if that != null
      formatted = []
      for ele in data
        fmt =
          value: ele.id
          label: ele.name
          customProperties:
            server: ele.server

        if selected != '' and fmt.value == selected
          fmt.selected = true

        formatted.push fmt
      that.setChoices(formatted, 'value', 'label', true)

    return data
  )
  return

window.api.servers = server
window.api.groups = group
