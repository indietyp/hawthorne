heatmap = (selector, data, height = 400) ->
  year = new Date().getFullYear()

  chart = new frappe.Chart selector, {
    type: 'heatmap',
    data: {
      dataPoints: data,
      start: new Date("Januar 01, #{year} 00:00:00"),
      end: new Date("December 31, #{year} 00:00:00")
    },
    colors: ['#0B2545', '#13315C', '#054A91', '#3E7CB1', '#00A9FF'],
  }
  return

line = (selector, data, height = 400) ->
  return

window.style.charts =
  heatmap: heatmap
  line: line
