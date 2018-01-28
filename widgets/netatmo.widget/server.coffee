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
    keys = ['Temperature', 'CO2', 'Humidity', 'Noise']
    metrics = []
    for key in keys when data[key]?
      value = data[key]
      metric =
        type: key
        value: value
        unit: units[key]
      if key is 'CO2'
        if value <= 700
          metric.quality = 'good'
        else if value <= 1000
          metric.quality = 'fair'
        else if value <= 1300
          metric.quality = 'inferior'
        else
          metric.quality = 'bad'
      metrics.push(metric)
    return metrics

  server.handle 'stations', (query, respond, fail) ->
    netatmo.getDevicelist (error, devices, modules) ->
      return fail(error) if error?
      devices = devices.filter((device) -> server.config.stations.indexOf(device.station_name) isnt -1)
      return fail("No devices found") if devices.length == 0
      stations = []
      for device in devices
        stations.push
          name: device.module_name
          metrics: metricsFromDashboardData(device.dashboard_data)
        modules = modules.filter (module) ->
          device.modules.indexOf(module._id) isnt -1
        for module in modules
          stations.push
            name: module.module_name
            metrics: metricsFromDashboardData(module.dashboard_data)
      respond(stations)