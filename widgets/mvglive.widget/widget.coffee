(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  widget.loadPeriodic 'departures', 15, (error, responses) ->
    container.empty()
    if error?
      container.text(error)
      return
    now = new Date()
    for response in responses
      board = $('<div></div>').addClass('station').appendTo(container)
      $('<div></div>').addClass('name').text(response.station).appendTo(board)
      groups = {}
      for departure in response.departures
        key = departure.line + ':' + departure.destination
        group = groups[key]
        unless group?
          group =
            line: departure.line
            color: departure.color
            destination: departure.destination
            times: []
          groups[key] = group
        group.times.push(departure.time)
      groups = (value for key,value of groups).sort (a,b) ->
        return 1 if a.line > b.line
        return -1 if a.line < b.line
        return 1 if a.line is b.line and a.destination > b.destination
        return -1 if a.line is b.line and a.destination < b.destination
        return 0
      previousLine = null
      for group in groups
        times = group.times.map (date) ->
          departureDate = new Date(parseInt(date))
          timeUntilDeparture = departureDate - now
          minutes = Math.round(timeUntilDeparture / (1000.0 * 60.0))
          return Math.max(minutes, 0)
        departureDiv = $('<div></div>').addClass('departure').appendTo(board)
        lineContainer = $('<div></div>').addClass('lineContainer').appendTo(departureDiv)
        $('<span></span>')
          .addClass('line')
          .text(group.line)
          .appendTo(lineContainer)
          .css('opacity', (if previousLine is group.line then '0' else '1'))
        $('<span></span>')
          .addClass('destination')
          .text(group.destination)
          .appendTo(departureDiv)
        timesDiv = $('<span></span>')
          .addClass('times')
          .appendTo(departureDiv)
        firstTime = yes
        for time in times[0..2]
          unless firstTime
            $('<span></span>')
              .addClass('time')
              .text(', ')
              .appendTo(timesDiv)
          minutesEl = $('<span></span>')
            .addClass('time')
            .text(time)
            .appendTo(timesDiv)
          if time <= response.walkingDistanceMinutes
            minutesEl.addClass('critical')
          firstTime = no
        $('<span></span>')
          .addClass('time')
          .addClass('minutes')
          .text(' Min')
          .appendTo(timesDiv)
        previousLine = group.line
