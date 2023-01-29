(widget) ->
  container = widget.div.find('.container')
  previousConfigs = null
  container.text widget.string("loading")

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
        $('<img/>').addClass('icon').attr('src', '/homematic/resources/open-window.png').appendTo(div)
        $('<div/>').addClass('item').text(text).appendTo(div)
      else
        div.hide()

  widget.loadPeriodic 'views', 1, (error, configs) ->
    return if previousConfigs? and JSON.stringify(previousConfigs) == JSON.stringify(configs)
    previousConfigs = configs
    container.empty()
    if error?
      container.text(error)
      return
    for config in configs
      div = $('<div/>').addClass('view').addClass(config.view).appendTo(container)
      views[config.view](div, config.data)
