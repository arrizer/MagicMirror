(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')

    addMetric = (div, icon, value, unit) ->
      secondaryDiv = $('<div/>').addClass('metric').appendTo(div)
      $('<img/>').addClass('icon').attr('src', '/netatmo/resources/' + icon + '.png').appendTo(secondaryDiv)
      $('<span/>').addClass('value').text(value).appendTo(secondaryDiv)
      $('<span/>').addClass('unit').text(unit).appendTo(secondaryDiv)

    icons =
      'Humidity': 'humidity'
      'Noise': 'noise'
      'Pressure': 'pressure'
    
    refresh = ->
      widget.load 'stations', (error, stations) ->
        container.empty()
        if error?
          container.text(error)
          setTimeout (-> refresh()), 1000
          return
        for station in stations
          stationDiv = $('<div/>').addClass('station').appendTo(container)
          metricsDiv = $('<div/>').addClass('metrics')
          $('<span/>').addClass('name').text(station.name).appendTo(stationDiv)
          for metric in station.metrics
            if metric.type is 'Temperature'
              $('<div/>').addClass('temperature').text(Math.round(metric.value) + ' °C').appendTo(stationDiv)
            else
              metricDiv = $('<div/>').addClass('metric').appendTo(metricsDiv)
              icon = icons[metric.type]
              if icon?
                $('<img/>').addClass('icon').attr('src', "/netatmo/resources/#{icon}.png").appendTo(metricDiv)
              if metric.quality?
                $('<div/>').addClass('quality').addClass(metric.quality).appendTo(metricDiv)
              $('<span/>').addClass('value').text(metric.value).appendTo(metricDiv)
              $('<span/>').addClass('unit').text(metric.unit).appendTo(metricDiv)
          metricsDiv.appendTo(stationDiv)
         setTimeout (-> refresh()), 1000 * 60

    container.text widget.string("loading")
    refresh()