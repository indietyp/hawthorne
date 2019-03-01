heatmap = (selector, data) ->
  year = 31536000000
  today = new Date()
  past = new Date(today.getTime() - year)

  chart = new frappe.Chart selector, {
    type: 'heatmap',
    data: {
      dataPoints: data,
      start: past,
      end: today
    },
    colors: ['#eaf8ff', '#aae2ff', '#6acdff', '#2bb7ff', '#00a9ff'],
  }

  viewbox = (selector) ->
    parent = $(selector)
    height = $('.frappe-chart', parent)[0].getAttribute 'height'
    width = $('.frappe-chart', parent)[0].getAttribute 'width'
    $('.frappe-chart', parent)[0].setAttribute 'viewBox', "0 0 #{width} #{height}"

  viewbox(selector)

  observer = new MutationObserver (mutations, observer) ->
    mutations.forEach (mutation) ->
      if mutation.addedNodes.length > 0
        viewbox(selector)

  parent = $(selector)
  observer.observe($('.chart-container', parent)[0], {'childList': true})

  return

line = (selector, labels, data, height = 400, tooltip = ' ') ->
  chart = new frappe.Chart selector, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{values: data}]
    },
    colors: ['#00a9ff'],
    height: height,
    tooltipOptions: {
      formatTooltipY: (d) -> d + tooltip,
    }
  }

  return

window.style.charts =
  heatmap: heatmap
  line: line
