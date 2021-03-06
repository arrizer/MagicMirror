(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    window.moment.locale(widget.globalConfig.language)

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

        
    refresh = ->
      widget.load 'forecast', (error, response) ->
        container.empty()
        if error?
          container.text(error.toString())
          return
        dayIndex = 0
        for day in response.days
          date = window.moment(new Date(parseInt(day.date) * 1000))
          div = $('<div></div>')
          div.addClass 'day'
          append = (cssclass, text) -> $('<div></div>').addClass(cssclass).text(text).appendTo(div)
          dayName = date.format('dddd')
          dayName = widget.string('today') if dayIndex is 0
          dayName = widget.string('tomorrow') if dayIndex is 1
          append 'name', dayName
          icon = $('<img></img>').addClass('icon').attr('src', "/weather/resources/#{day.icon}.png")
          div.append icon
          append 'temperatureMax', Math.round(day.temperatureHigh) + ' ' + widget.string('unit.temperature.' + response.units)
          append 'temperatureMin', Math.round(day.temperatureLow) + ' ' + widget.string('unit.temperature.' + response.units)
          append('precipitationProbability', Math.round(day.precipitationProbability) + ' %').addClass("level#{precipitationLevel(day.precipitationProbability)}")
          container.append(div)
          dayIndex++
    
    container.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , (1000 * 60 * 10)