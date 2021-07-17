(widget) ->
  widget.init = ->
    container = widget.div.find('.container')

    round = (value, digits = 0) ->
      exp = Math.pow(10, digits)
      return Math.round(value * exp) / exp

    formatNumber = (value) ->
      if value > 1000000
        return "#{widget.util.formatNumber(round(value / 1000000, 2))} mio"
      else if value > 1000
        return "#{widget.util.formatNumber(round(value / 1000, 1))} k"
      else
        return widget.util.formatNumber(value)

    formatPercentage = (value) ->
      widget.util.formatNumber(Math.round(value * 10000) / 100) + " %"

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
        
        addMetric = (metricsEl, metric, text, cssClass) ->
          metricEl = $('<div>').addClass('metric').appendTo(metricsEl)
          valueEl = $('<div>').addClass('value').addClass(metric).text(text).appendTo(metricEl)
          valueEl.addClass(cssClass) if cssClass?
          $('<div>').addClass('label').text(widget.string("metric.#{metric}")).appendTo(metricEl)
        
        el = addItem(result.stats.label)
        for metric in ['cases', 'recovered', 'dead', 'incidence']
          addMetric(el, metric, formatNumber(result.stats[metric]))
        addMetric(el, 'rvalue', formatNumber(result.stats.rvalue), if result.stats.rvalue > 1 then 'range_bad' else 'range_good')
        
        for district in result.districts
          el = addItem(district.label)
          for metric in ['incidence']
            addMetric(el, metric, formatNumber(district[metric]))

        el = addItem(widget.string("vaccinations.title"))
        for metric, value of result.vaccinationProgress
          addMetric(el, "vaccinations.#{metric}", formatPercentage(value))

    container.text widget.string("loading")
    setInterval (-> refresh()), (1000 * 60 * 15)
    refresh()