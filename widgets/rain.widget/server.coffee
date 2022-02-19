Request = require 'request'

module.exports = (server) =>
  log = server.log
  areaID = null
            
  resolveCoordinateToArea = (latitude, longitude, next) ->
    log.debug "Resolving coordinate #{latitude} / #{longitude} to area"
    url = 'http://feed.alertspro.meteogroup.com/AlertsPro/AlertsProPollService.php?method=lookupCoord&lat=' + latitude + '&lon=' + longitude
    log.debug url
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
    log.debug url
    Request (url: url, json: yes), (error, response, result) ->
      return next error if error?
      return next new Error("No rain forecast available for the region") if !result?
      rain = {}
      unless result.intensity is -1
        if result.intensity < 0.33
          rain.intensity = 1
        else if result.intensity < 0.77
          rain.intensity = 2
        else
          rain.intensity = 3
        
      if (result.startMin is -1 and result.endMin is -1) or !rain.intensity?
        rain.state = 'clear'
      else if result.startMin > 0
        rain.state = 'predicted-begin'
        rain.minutes = result.startMin
      else if result.endMin > 0
        rain.state = 'predicted-end'
        rain.minutes = result.endMin
      else
        rain.state = 'raining'
      next null, rain
        
  server.init = (next) ->
    if server.config.areaID?
      areaID = server.config.areaID
      next()
    else
      resolveCoordinateToArea server.config.latitude, server.config.longitude, (error, result) ->
        if error? 
          log.error "Failed to resolve coordinate: #{error}"
        else
          areaID = result
        next()
    
  server.handle 'rainforecast', (query, respond, fail) ->
    requestRainPrediction (error, result) ->
      return fail(error) if error?
      respond(result)