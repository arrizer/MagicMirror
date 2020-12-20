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
      widget.load 'stats', (error, result) ->
        container.empty()
        if error?
          container.text(error)
          setTimeout (-> refresh()), 1000
          return
        
        addItem = (label) ->
          el = $('<div>').addClass('item').appendTo(container)
          $('<div>').addClass('label').text(label).appendTo(el)
          metricsEl = $('<div>').addClass('metrics').appendTo(el)
          return metricsEl
        
        addMetric = (metricsEl, metric, value) ->
          metricEl = $('<div>').addClass('metric').appendTo(metricsEl)
          $('<div>').addClass('value').addClass(metric).text(formatNumber(value)).appendTo(metricEl)
          $('<div>').addClass('label').text(widget.string("metric.#{metric}")).appendTo(metricEl)
        
        for place in result.places
          el = addItem(place.label)
          for metric in ['infected', 'sick', 'recovered', 'dead']
            addMetric(el, metric, place[metric])
        
        for county in result.counties
          el = addItem(county.label)
          for metric in ['incidence']
            addMetric(el, metric, county[metric])

        setTimeout (-> refresh()), (1000 * 60 * 15)

    container.text widget.string("loading")
    refresh()