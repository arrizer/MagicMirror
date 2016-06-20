(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    refresh = ->
      widget.load 'departures', (error, responses) ->
        container.empty()
        if error?
          container.text(error)
          return
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
            times = group.times.map (time) ->
              return Math.round((new Date(parseInt(time)) - new Date()) / (1000.0 * 60.0))
            departureDiv = $('<div></div>').addClass('departure').appendTo(board)
            $('<span></span>').addClass('line').text(group.line).appendTo(departureDiv).css('opacity', (if previousLine is group.line then '0' else '1'))
            $('<span></span>').addClass('destination').text(group.destination).appendTo(departureDiv)
            $('<span></span>').addClass('time').text(times[0..1].join(', ') + ' Min').appendTo(departureDiv)
            previousLine = group.line
    container.text widget.string("loading")
    setInterval ->
      refresh()
    , (1000 * 30)
    refresh()