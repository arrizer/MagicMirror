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
      if icon?
        iconImage.attr('src', '/rain/resources/' + icon + '.png')
        iconImage.show()
      else
        iconImage.hide()
      status.text(text)

    refresh = ->  
      widget.load 'rainforecast', (error, response) ->
        container.css(opacity: '1')
        immediate = if response.minutes? and response.minutes <= 1 then '-immediate' else ''
        if error?
          setState(null, error)
          setTimeout (-> refresh()), 1000 
          return
        else
          setTimeout (-> refresh()), 1000 * 60

        if response.state is 'clear'
          widget.div.hide()
        else
          widget.div.show()

        if response.state is 'clear'
          setState('clear', widget.string('clear'))
        else if response.state is 'predicted-begin'
          key = INTENSITY_KEYS[response.intensity]
          setState(key, widget.string('predicted-begin' + immediate, widget.string(key), response.minutes.toString()))
        else if response.state is 'predicted-end'
          key = INTENSITY_KEYS[response.intensity]
          setState('end', widget.string('predicted-end' + immediate, widget.string(key), response.minutes.toString()))
        else if response.state is 'raining'
          key = INTENSITY_KEYS[response.intensity]
          setState(key, widget.string('raining', widget.string(key)))
  
    setState(null, widget.string('loading'))
    refresh()