(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  COLOR_QUALITY_BEST = (red: 119, green: 195, blue: 68)
  COLOR_QUALITY_AVERAGE = (red: 255, green: 147, blue: 0)
  COLOR_QUALITY_WORST = (red: 255, green: 38, blue: 0)

  icons =
    'Humidity': 'humidity'
    'Noise': 'noise'
    'Pressure': 'pressure'

  addMetric = (div, icon, value, unit) ->
    secondaryDiv = $('<div/>').addClass('metric').appendTo(div)
    $('<img/>').addClass('icon').attr('src', '/netatmo/resources/' + icon + '.png').appendTo(secondaryDiv)
    $('<span/>').addClass('value').text(value).appendTo(secondaryDiv)
    $('<span/>').addClass('unit').text(unit).appendTo(secondaryDiv)

  mixColors = (color1, color2, percentage) ->
    result =
      red: (color1.red * (1 - percentage)) + (color2.red * percentage)
      green: (color1.green * (1 - percentage)) + (color2.green * percentage)
      blue: (color1.blue * (1 - percentage)) + (color2.blue * percentage)
    return result

  colorFromQuality = (quality) ->
    if quality < 0.5
      return mixColors(COLOR_QUALITY_WORST, COLOR_QUALITY_AVERAGE, quality * 2)
    else
      return mixColors(COLOR_QUALITY_AVERAGE, COLOR_QUALITY_BEST, (quality - 0.5) * 2)

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
            color = colorFromQuality(metric.quality)
            $('<div/>').addClass('quality').css('background-color', "rgb(#{color.red},#{color.green},#{color.blue})").appendTo(metricDiv)
          $('<span/>').addClass('value').text(metric.value).appendTo(metricDiv)
          $('<span/>').addClass('unit').text(metric.unit).appendTo(metricDiv)
      metricsDiv.appendTo(stationDiv)