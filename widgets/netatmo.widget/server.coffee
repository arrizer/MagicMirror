Netatmo = require 'netatmo'

module.exports = (server) =>
  log = server.log
  netatmo = new Netatmo(server.config.auth)

  units =
    'Temperature': '°C'
    'Humidity': '%'
    'CO2': 'ppm'
    'Noise': 'db'
    'Pressure': 'mBar'

  metricsFromDashboardData = (data) ->
    return [] unless data?
    keys = ['Temperature', 'CO2', 'Humidity']
    metrics = []
    for key in keys when data[key]?
      value = data[key]
      metric =
        type: key
        value: value
        unit: units[key]
      if key is 'CO2'
        if value <= 1000
          metric.quality = 'good'
        else if value <= 1500
          metric.quality = 'fair'
        else if value <= 2000
          metric.quality = 'inferior'
        else
          metric.quality = 'bad'
      metrics.push(metric)
    return metrics

  stationFromObject = (object) ->
    moduleConfig = null
    for config in server.config.modules
      if config.module is object.module_name
        moduleConfig = config
    return null unless moduleConfig?
    station =
      module: object.module_name
      name: moduleConfig.title
      metrics: metricsFromDashboardData(object.dashboard_data)
    return station

  server.handle 'stations', (query, respond, fail) ->
    netatmo.getDevicelist (error, devices, modules) ->
      return fail(error) if error?
      devices = devices.filter((device) -> server.config.stations.indexOf(device.station_name) isnt -1)
      return fail("No devices found") if devices.length == 0
      stations = []
      for device in devices
        station = stationFromObject(device)
        stations.push(station) if station?
        modules = modules.filter (module) ->
          device.modules.indexOf(module._id) isnt -1
        for module in modules
          station = stationFromObject(module)
          stations.push(station) if station?
      orderedStations = []
      for moduleConfig in server.config.modules
        for station in stations
          if station.module is moduleConfig.module
            orderedStations.push(station)
      stations = orderedStations
      respond(stations)