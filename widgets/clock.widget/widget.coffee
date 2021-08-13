(widget) ->
  timeDiv = widget.div.children('.time')
  dateDiv = widget.div.children('.date')

  updateTime = ->
    now = window.moment()
    window.moment.locale(widget.globalConfig.language)
    now.locale (widget.globalConfig.language or 'en')
    timeDiv.text now.format(widget.string('format.time'))
    dateDiv.text now.format(widget.string('format.date'))

  updateTime()
  setInterval updateTime, 1000