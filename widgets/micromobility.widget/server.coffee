Request = require 'request-promise-native'
Async = require 'async'

calculateDistance = (c1, c2) ->
  R = 6371
  dLat = (c2.latitude - c1.latitude) * Math.PI / 180
  dLon = (c2.longitude - c1.longitude) * Math.PI / 180
  a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(c1.latitude * Math.PI / 180 ) * Math.cos(c2.latitude * Math.PI / 180 ) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  d = R * c
  return d * 1000

module.exports = (server) =>
  log = server.log
  config = server.config
    
  server.init = (next) ->
    next()

  providers =
    tier: (config) ->
      request =
        url: "https://platform.tier-services.io/vehicle?zoneId=#{encodeURIComponent(config.zoneID)}"
        json: yes
        headers:
          'X-API-Key': 'bpEUTJEBTf74oGRWxaIcW7aeZMzDDODe1yBoSxi2'
      response = await Request(request)
      return response.data.map (vehicle) ->
        result =
          kind: 'scooter'
          latitude: vehicle.lat
          longitude: vehicle.lng
          id: vehicle.code
        return result
    mvgbike: (config) ->
      request =
        url: "https://multimobil-core.mvg.de/v12/service/v12/networkState/networkState?MVG_RAD=0"
        json: yes
      response = await Request(request)
      return response.addedBikes.map (vehicle) ->
        result =
          kind: 'bicycle'
          latitude: vehicle.latitude
          longitude: vehicle.longitude
          id: vehicle.id
        return result

  loadAllVehicles = ->
    providerNames = Object.keys(config.providers)
    results = {}
    await Promise.all providerNames.map (providerName) -> 
      results[providerName] = await providers[providerName](config.providers[providerName])
      return Promise.resolve()
    return results
    
  server.handle 'vehicles', (query, respond, fail) ->
    allVehicles = await loadAllVehicles()
    for provider,vehicles of allVehicles
      for vehicle in vehicles
        vehicle.distance = calculateDistance(config.location, vehicle)
      vehicles = vehicles.sort (a,b) ->
        return -1 if a.distance < b.distance
        return 1 if a.distance > b.distance
        return 0
      allVehicles[provider] = vehicles[..2]
    respond(allVehicles)