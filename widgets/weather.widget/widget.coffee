(widget) ->
  container = widget.div.find('.container')
  window.moment.locale(widget.globalConfig.language)
  container.text widget.string('loading')
    
  precipitationLevel = (percent) ->
    if percent > 84
      return 4
    else if percent > 68
      return 3
    else if percent > 52
      return 2
    else if percent > 36
      return 1
    else
      return 0
  
  widget.loadPeriodic 'forecast', 60 * 10, (error, response) ->
    container.empty()
    if error?
      container.text(error.toString())
      return
    dayIndex = 0
    for day in response.days
      date = window.moment(new Date(day.date))
      div = $('<div></div>')
      div.addClass 'day'
      append = (cssclass, text) -> $('<div></div>').addClass(cssclass).text(text).appendTo(div)
      dayName = date.format('dddd')
      dayName = widget.string('today') if dayIndex is 0
      append 'name', dayName
      icon = $('<div></div>').addClass('icon').css('background-image', "url(/weather/resources/#{day.icon}.png)")
      div.append icon
      append 'temperatureMax', Math.round(day.temperatureHigh) + ' ' + widget.string('unit.temperature.celsius')
      append 'temperatureMin', Math.round(day.temperatureLow) + ' ' + widget.string('unit.temperature.celsius')
      precipitationEl = append('precipitationProbability', Math.round(day.precipitationProbability) + ' %').addClass("level#{precipitationLevel(day.precipitationProbability)}")
      precipitationEl.css('opacity', 0) if day.precipitationProbability < 1
      container.append(div)
      dayIndex++