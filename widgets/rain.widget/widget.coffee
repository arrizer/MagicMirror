(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    status = widget.div.find('.text')
    iconImage = widget.div.find('.icon')
    
    INTENSITY_KEYS =
      '1': 'intensity-light'
      '2': 'intensity-medium'
      '3': 'intensity-heavy'
      
    setState = (icon, text) ->
      iconImage.attr('src', '/rain/resources/' + icon + '.png')
      status.text(text)

    refresh = ->  
      widget.load 'rainforecast', (error, response) ->
        container.css(opacity: '1')
        if error?
          status.text(error)
          return
        if response.state is 'clear'
          container.css(opacity: '0.5')
          setState('clear', widget.string('clear'))
        else if response.state is 'predicted-begin'
          key = INTENSITY_KEYS[response.intensity]
          setState(key, widget.string('predicted-begin', widget.string(key), response.minutes.toString()))
        else if response.state is 'predicted-end'
          key = INTENSITY_KEYS[response.intensity]
          setState('end', widget.string('predicted-end', widget.string(key), response.minutes.toString()))
        else if response.state is 'raining'
          setState('raining', widget.string('raining', widget.string(INTENSITY_KEYS[response.intensity])))
  
    status.text widget.string('loading')    
    refresh()
    setInterval ->
      refresh()
    , (1000 * 60)