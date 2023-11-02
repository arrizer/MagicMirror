(widget) ->
  container = widget.div.find('.container')
  previousResponse = null
  container.text widget.string("loading")

  widget.loadPeriodic 'openWindows', 1, (error, response) ->
    return if previousResponse? and JSON.stringify(previousResponse) == JSON.stringify(response)
    previousResponse = response
    container.empty()
    if error?
      container.text(error)
      return
    div = $('<div/>').addClass('view').addClass('openWindows').appendTo(container)
    windows = []
    for name,isOpen of response
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
