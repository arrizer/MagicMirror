Request = require 'request'

module.exports = (server) =>
  log = server.log
  areaID = null
            
  resolveCoordinateToArea = (latitude, longitude, next) ->
    url = 'http://feed.alertspro.meteogroup.com/AlertsPro/AlertsProPollService.php?method=lookupCoord&lat=' + latitude + '&lon=' + longitude
    Request (url: url, json: yes), (error, response, result) ->
      return next error if error?
      if result.push? and result.length >= 0
        result = result[0].AREA_ID
        next null, result
      else
        next new Error("Failed to resolve region for rain prediciton service")
          
  requestRainPrediction = (next) ->
    return next new Error("Area not supported") unless areaID?
    url = 'http://weatherpro.consumer.meteogroup.com/weatherpro/RainService.php?method=getRainChart&areaID=' + areaID
    Request (url: url, json: yes), (error, response, result) ->
      return next error if error?
      return next new Error("No rain forecast available for the region") if !result?
      rain = {}
      if result.startMin is -1 and result.endMin is -1
        rain.state = 'clear'
      else if result.startMin > 0
        rain.state = 'predicted-begin'
        rain.minutes = result.startMin
        rain.intensity = result.intensity
      else if result.endMin > 0
        rain.state = 'predicted-end'
        rain.minutes = result.endMin
        rain.intensity = result.intensity
      else
        rain.state = 'raining'
        rain.intensity = result.intensity
      next null, rain
        
  server.init = (next) ->
    resolveCoordinateToArea server.config.latitude, server.config.longitude, (error, result) ->
      log.error "Failed to resolve coordinate. Rain prediction not supported!" if error?
      areaID = result unless error?
      next()
    
  server.handle 'rainforecast', (query, respond, fail) ->
    requestRainPrediction (error, result) ->
      return fail(error) if error?
      respond(result)