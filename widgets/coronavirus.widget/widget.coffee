(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')

    round = (value, digits = 0) ->
      exp = Math.pow(10, digits)
      Math.round(value * exp) / exp

    formatNumber = (value) ->
      if value > 1000000
        return "#{round(value / 1000000, 2)} mio"
      else if value > 1000
        return "#{round(value / 1000, 1)} k"
      else
        return value.toString()

    refresh = ->
      widget.load 'stats', (error, items) ->
        container.empty()
        if error?
          container.text(error)
          setTimeout (-> refresh()), 1000
          return
        for item in items
          itemEl = $('<div>').addClass('item').appendTo(container)
          $('<div>').addClass('label').text(item.label).appendTo(itemEl)
          metricsEl = $('<div>').addClass('metrics').appendTo(itemEl)
          for metric in ['infected', 'sick', 'recovered', 'dead']
            metricEl = $('<div>').addClass('metric').appendTo(metricsEl)
            $('<div>').addClass('value').addClass(metric).text(formatNumber(item[metric])).appendTo(metricEl)
            $('<div>').addClass('label').text(widget.string("metric.#{metric}")).appendTo(metricEl)
        setTimeout (-> refresh()), (1000 * 60 * 15)

    container.text widget.string("loading")
    refresh()