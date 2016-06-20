(widget) ->
  widget.init = (next) ->
    container = widget.div.find('.container')

    addSecondary = (div, icon, value, unit) ->
      secondaryDiv = $('<div/>').addClass('secondary').appendTo(div)
      $('<img/>').addClass('icon').attr('src', '/netatmo/resources/' + icon + '.png').appendTo(secondaryDiv)
      $('<span/>').addClass('value').text(value).appendTo(secondaryDiv)
      $('<span/>').addClass('unit').text(unit).appendTo(secondaryDiv)
    
    refresh = ->
      widget.load 'stations', (error, stations) ->
        container.empty()
        if error?
          container.text(error)
          return
        for station in stations
          device = station.device
          stationDiv = $('<div/>').addClass('station').appendTo(container)
          deviceDiv = $('<div/>').addClass('device').appendTo(stationDiv)
          leftDiv = $('<div/>').addClass('page').appendTo(deviceDiv)
          rightDiv = $('<div/>').addClass('page').appendTo(deviceDiv)
          $('<span/>').addClass('name').text(device.station_name + ' ' + device.module_name).appendTo(leftDiv)
          $('<div/>').addClass('temperature_indoor').text(device.dashboard_data.Temperature + ' °C').appendTo(leftDiv)
          addSecondary(rightDiv, 'humidity', device.dashboard_data.Humidity, '%')
          addSecondary(rightDiv, 'pressure', device.dashboard_data.Pressure, 'mBar')
          addSecondary(rightDiv, 'co2', device.dashboard_data.CO2, 'ppm')
          addSecondary(rightDiv, 'noise', device.dashboard_data.Noise, 'db')
          for module in station.modules
            moduleDiv = $('<div/>').addClass('device').appendTo(stationDiv)
            leftDiv = $('<div/>').addClass('page').appendTo(moduleDiv)
            rightDiv = $('<div/>').addClass('page').appendTo(moduleDiv)
            $('<span/>').addClass('name').text(module.module_name).appendTo(leftDiv)
            if module.type is 'NAModule1'
              # Outdoor module
              $('<div/>').addClass('temperature_outdoor').text(module.dashboard_data.Temperature + ' °C').appendTo(leftDiv)
              addSecondary(rightDiv, 'humidity', module.dashboard_data.Humidity, '%')

    container.text widget.string("loading")
    setInterval ->
      refresh()
    , (1000 * 60)
    refresh()