(widget) ->
  widget.init = (next) ->
    skycons = new window.Skycons(color: 'white')
    container = widget.div.find('.container')
    animatedIcons = []
    window.moment.locale(widget.globalConfig.language)
    
    icons =
      'chanceflurries': Skycons.SNOW
      'chancerain': Skycons.RAIN
      'chancesleet': Skycons.SLEET
      'chancesnow': Skycons.SNOW
      'chancetstorms': Skycons.RAIN
      'clear': Skycons.CLEAR_DAY
      'cloudy': Skycons.CLOUDY
      'flurries': Skycons.SNOW
      'fog': Skycons.FOG
      'hazy': Skycons.FOG
      'mostlycloudy': Skycons.CLOUDY
      'mostlysunny': Skycons.CLEAR_DAY
      'partlycloudy': Skycons.PARTLY_CLOUDY_DAY
      'partlysunny': Skycons.PARTLY_CLOUDY_DAY
      'rain': Skycons.RAIN
      'sleet': Skycons.SLEET
      'snow': Skycons.SNOW
      'sunny': Skycons.CLEAR_DAY
      'tstorms': Skycons.RAIN
      'unknown': Skycons.CLEAR_DAY
    
    refresh = ->
      widget.load 'forecast', (error, response) ->
        if error?
          container.text(error.toString())
          return
        container.empty()
        for icon in animatedIcons
          skycons.remove(icon[0])
        animatedIcons = []
        dayIndex = 0
        for day in response.forecast.simpleforecast.forecastday[ .. 6]
          date = window.moment(new Date(parseInt(day.date.epoch) * 1000))
          div = $('<div></div>')
          div.addClass 'day'
          append = (cssclass, text) -> div.append $('<div></div>').addClass(cssclass).text(text)
          dayName = date.format('dddd')
          dayName = widget.string('today') if dayIndex is 0
          dayName = widget.string('tomorrow') if dayIndex is 1
          append 'name', dayName
          icon = $('<canvas></canvas>').addClass('icon')
          div.append icon
          skycons.add(icon[0], icons[day.icon])
          animatedIcons.push icon
          append 'temperatureMax', Math.round(day.high[response.units]) + ' ' + widget.string('unit.temperature.' + response.units)
          append 'temperatureMin', Math.round(day.low[response.units]) + ' ' + widget.string('unit.temperature.' + response.units)
          container.append(div)
          dayIndex++
        skycons.play()
    
    container.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , (1000 * 60 * 10)