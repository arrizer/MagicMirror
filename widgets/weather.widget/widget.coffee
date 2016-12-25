(widget) ->
  widget.init = (next) ->
    skycons = new window.Skycons(color: 'white')
    container = widget.div.find('.container')
    animatedIcons = []
    window.moment.locale(widget.globalConfig.language)
    
    icons =
      'clear-day': Skycons.CLEAR_DAY
      'clear-night': Skycons.CLEAR_NIGHT
      'rain': Skycons.RAIN
      'snow': Skycons.SNOW
      'sleet': Skycons.SLEET
      'wind': Skycons.WIND
      'fog': Skycons.FOG
      'cloudy': Skycons.CLOUDY
      'partly-cloudy-day': Skycons.PARTLY_CLOUDY_DAY
      'partly-cloudy-night': Skycons.PARTLY_CLOUDY_NIGHT
    
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
        for day in response.daily.data[ .. 6]
          date = window.moment(new Date(day.time * 1000))
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
          append 'temperatureMax', Math.round(day.temperatureMax) + ' ' + widget.string('unit.temperature.' + response.flags.units)
          append 'temperatureMin', Math.round(day.temperatureMin) + ' ' + widget.string('unit.temperature.' + response.flags.units)
          container.append(div)
          dayIndex++
        skycons.play()
    
    container.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , (1000 * 60 * 10)