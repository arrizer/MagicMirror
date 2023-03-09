(widget) ->
  container = widget.div.find('.container')
  window.moment.locale(widget.globalConfig.language)
  container.text widget.string('loading')
    
  precipitationLevel = (amount) ->
    Math.floor((Math.min(amount, 10.0) / 10.0)  * 4)
  
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
      icon = $('<div></div>').addClass('icon').css('background-image', "url(/weather/resources/condition_#{day.condition}.png)")
      div.append icon
      append 'temperatureMax', Math.round(day.temperatureHigh) + ' ' + widget.string('unit.temperature.celsius')
      append 'temperatureMin', Math.round(day.temperatureLow) + ' ' + widget.string('unit.temperature.celsius')      
      precipitationAmountEl = $('<div></div>')
        .addClass('precipitation')
        .addClass('amount')
        .appendTo(div)
      $('<img/>')
        .attr('src', "/weather/resources/precipitation_#{precipitationLevel(day.precipitationAmount)}.png")
        .appendTo(precipitationAmountEl)
      $('<span></span>')
        .text(widget.util.formatNumber(day.precipitationAmount) + ' mm')
        .appendTo(precipitationAmountEl)
      precipitationProbabilityEl = $('<div></div>')
        .addClass('precipitation')
        .addClass('probability')
        .text(Math.round(day.precipitationProbability) + ' %')
        .appendTo(div)
      if day.precipitationProbability < 1 or day.precipitationAmount < 0.1
        precipitationAmountEl.css('opacity', 0)
        precipitationProbabilityEl.css('opacity', 0)
        
      container.append(div)
      dayIndex++