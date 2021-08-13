(widget) ->
  container = widget.div.find('.container')
  container.text widget.string("loading")

  widget.loadPeriodic 'vehicles', 30, (error, response) ->
    container.empty()
    if error?
      container.text(error)
      return
    for provider in Object.keys(response).sort()
      vehicles = response[provider]
      continue unless vehicles.length > 0
      group = $('<div></div>').addClass('group').appendTo(container)
      $('<img/>').addClass('icon').attr('src', "/micromobility/resources/provider-#{provider}.png").appendTo(group)
      for vehicle in vehicles
        distance = vehicle.distance
        formattedDistance = if distance < 1000 then "#{Math.round(distance)} m" else "#{Math.round(distance / 100) / 10} km"
        div = $('<div></div>').addClass('vehicle').text(formattedDistance).appendTo(group)
        div.addClass('far-away') if distance > 500
