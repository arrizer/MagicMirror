(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  icons =
    'Humidity': 'humidity'
    'Noise': 'noise'
    'Pressure': 'pressure'

  addMetric = (div, icon, value, unit) ->
    secondaryDiv = $('<div/>').addClass('metric').appendTo(div)
    $('<img/>').addClass('icon').attr('src', '/netatmo/resources/' + icon + '.png').appendTo(secondaryDiv)
    $('<span/>').addClass('value').text(value).appendTo(secondaryDiv)
    $('<span/>').addClass('unit').text(unit).appendTo(secondaryDiv)

  widget.loadPeriodic 'stations', 60, (error, stations) ->
    container.empty()
    if error?
      container.text(error)
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