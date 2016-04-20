(widget) ->
  timeDiv = widget.div.children('.time')
  dateDiv = widget.div.children('.date')

  widget.init = (next) ->
    updateTime()
    setInterval updateTime, 1000
  
  updateTime = ->
    now = window.moment()
    now.locale (widget.globalConfig.language or 'en')
    timeDiv.text now.format(widget.string('format.time'))
    dateDiv.text now.format(widget.string('format.date'))
