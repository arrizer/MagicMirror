(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  COLOR_QUALITY_BEST = (red: 119, green: 195, blue: 68)
  COLOR_QUALITY_AVERAGE = (red: 255, green: 147, blue: 0)
  COLOR_QUALITY_WORST = (red: 255, green: 38, blue: 0)

  PROMINENT_METRICS = ['Temperature', 'sum_rain_24', 'WindStrength']
  ANGLE_METRICS = ['WindAngle', 'GustAngle']
  RAIN_METRICS = ['sum_rain_24', 'sum_rain_1']

  icons =
    'Humidity': 'humidity'
    'Noise': 'noise'
    'Pressure': 'pressure'
    'sum_rain_1': 'rain'
    'GustStrength': 'gust'

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
      previousMetricDiv = null
      for metric in station.metrics
        isAngle = ANGLE_METRICS.indexOf(metric.type) != -1
        isProminent = PROMINENT_METRICS.indexOf(metric.type) != -1
        isRain = RAIN_METRICS.indexOf(metric.type) != -1
        if isAngle
          compassDiv = $('<div/>').addClass('compass').appendTo(previousMetricDiv)
          $('<div/>').addClass('needle').css('transform' , "rotate(#{metric.value}deg)").appendTo(compassDiv)
        else
          parentDiv = if isProminent then stationDiv else metricsDiv
          metricDiv = $('<div/>').addClass('metric').addClass(metric.type.toLowerCase()).appendTo(parentDiv)
          previousMetricDiv = metricDiv
          metricDiv.addClass('prominent') if isProminent
          icon = icons[metric.type]
          if icon?
            $('<img/>').addClass('icon').attr('src', "/netatmo/resources/#{icon}.png").appendTo(metricDiv)
          if metric.quality?
            color = colorFromQuality(metric.quality)
            $('<div/>').addClass('quality').css('background-color', "rgb(#{color.red},#{color.green},#{color.blue})").appendTo(metricDiv)
          if isRain and metric.value <= 0
            metricDiv.css('opacity', 0.5)
          value = metric.value
          minimumFractionDigits = 0
          if isRain
            minimumFractionDigits = 1 if value > 0
            value = Math.round(value * 10) / 10
          else
            value = Math.round(value)
          $('<span/>').addClass('value').text(widget.util.formatNumber(value, (minimumFractionDigits: minimumFractionDigits))).appendTo(metricDiv)
          $('<span/>').addClass('unit').text(metric.unit).appendTo(metricDiv)
      metricsDiv.appendTo(stationDiv)
