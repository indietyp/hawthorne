heatmap = (selector, data, height = 400) ->
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
  return

line = (selector, data, height = 400) ->
  return

window.style.charts =
  heatmap: heatmap
  line: line
