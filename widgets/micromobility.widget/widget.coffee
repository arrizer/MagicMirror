(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')
    refresh = ->
      widget.load 'vehicles', (error, response) ->
        container.empty()
        if error?
          container.text(error)
          setTimeout (-> refresh()), 1000
          return
        for provider, vehicles of response
          continue unless vehicles.length > 0
          group = $('<div></div>').addClass('group').appendTo(container)
          $('<img/>').addClass('icon').attr('src', "/micromobility/resources/provider-#{provider}.png").appendTo(group)
          #$('<div></div>').addClass('count').text(vehicles.length).appendTo(group)
          for vehicle in vehicles
            distance = vehicle.distance
            distance = if distance < 1000 then "#{Math.round(distance)} m" else "#{Math.round(distance / 100) / 10} km"
            $('<div></div>').addClass('vehicle').text(distance).appendTo(group)

    container.text widget.string("loading")
    setInterval (-> refresh()), (1000 * 15)
    refresh()