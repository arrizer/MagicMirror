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

    formatPercentage = (value) ->
      return (Math.round(value * 10000) / 100) + " %"

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
        
        addMetric = (metricsEl, metric, text) ->
          metricEl = $('<div>').addClass('metric').appendTo(metricsEl)
          $('<div>').addClass('value').addClass(metric).text(text).appendTo(metricEl)
          $('<div>').addClass('label').text(widget.string("metric.#{metric}")).appendTo(metricEl)
        
        for place in result.places
          el = addItem(place.label)
          for metric in ['infected', 'sick', 'recovered', 'dead']
            addMetric(el, metric, formatNumber(place[metric]))
        
        for county in result.counties
          el = addItem(county.label)
          for metric in ['incidence']
            addMetric(el, metric, formatNumber(county[metric]))

        el = addItem(widget.string("vaccinations.title"))
        for metric, value of result.vaccinationProgress
          addMetric(el, "vaccinations.#{metric}", formatPercentage(value))

    container.text widget.string("loading")
    setInterval (-> refresh()), (1000 * 60 * 15)
    refresh()