Netatmo = require 'netatmo'

module.exports = (server) =>
  log = server.log
  netatmo = new Netatmo(server.config.auth)
        
  server.handle 'stations', (query, respond, fail) ->
    netatmo.getDevicelist (error, devices, modules) ->
      return fail(error) if error?
      devices = devices.filter (device) ->
        server.config.stations.indexOf(device.station_name) isnt -1
      stations = devices.map (device) ->
        modules = modules.filter (module) ->
          device.modules.indexOf(module._id) isnt -1
        station =
          device: device
          modules: modules
        return station
      console.log stations[0].modules
      respond(stations)