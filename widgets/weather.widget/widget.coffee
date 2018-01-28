(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    window.moment.locale(widget.globalConfig.language)
    
    icons =
      'chanceflurries': 'snow'
      'chancerain': 'rain'
      'chancesleet': 'sleet'
      'chancesnow': 'snow'
      'chancetstorms': 'thunderstorm'
      'clear': 'sunny'
      'cloudy': 'cloudy'
      'flurries': 'snow'
      'fog': 'fog'
      'hazy': 'fog'
      'mostlycloudy': 'cloudy'
      'mostlysunny': 'sunny'
      'partlycloudy': 'partly-cloudy'
      'partlysunny': 'partly-cloudy'
      'rain': 'rain'
      'sleet': 'sleet'
      'snow': 'snow'
      'sunny': 'sunny'
      'tstorms': 'rain'
      'unknown': 'sunny'
    
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
          append = (cssclass, text) -> div.append $('<div></div>').addClass(cssclass).text(text)
          dayName = date.format('dddd')
          dayName = widget.string('today') if dayIndex is 0
          dayName = widget.string('tomorrow') if dayIndex is 1
          append 'name', dayName
          icon = $('<img></img>').addClass('icon').attr('src', "/weather/resources/#{icons[day.conditions]}.png")
          div.append icon
          append 'temperatureMax', Math.round(day.temperatureHigh) + ' ' + widget.string('unit.temperature.' + response.units)
          append 'temperatureMin', Math.round(day.temperatureLow) + ' ' + widget.string('unit.temperature.' + response.units)
          container.append(div)
          dayIndex++
    
    container.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , (1000 * 60 * 10)