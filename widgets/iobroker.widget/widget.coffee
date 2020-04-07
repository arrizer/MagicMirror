(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    previousConfigs = null

    views =
      openWindows: (div, data) ->
        windows = []
        for name,isOpen of data
          windows.push(name) if isOpen
        windows.sort()
        if windows.length > 0
          text = ""
          if windows.length >= 2
            text = "#{windows[ .. windows.length - 2].join(", ")} #{widget.string("openWindows.open.and")} #{windows[windows.length - 1]}"
          else
            text = windows[0]
          text = widget.string("openWindows.open", text)
          $('<img/>').addClass('icon').attr('src', '/iobroker/resources/open-window.png').appendTo(div)
          $('<div/>').addClass('item').text(text).appendTo(div)
        else
          div.hide()

    refresh = ->
      widget.load 'views', (error, configs) ->
        return if previousConfigs? and JSON.stringify(previousConfigs) == JSON.stringify(configs)
        previousConfigs = configs
        container.empty()
        if error?
          container.text(error)
          return
        for config in configs
          div = $('<div/>').addClass('view').addClass(config.view).appendTo(container)
          views[config.view](div, config.data)

    container.text widget.string("loading")
    setInterval ->
      refresh()
    , 1000
    refresh()