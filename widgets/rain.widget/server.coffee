module.exports = (server) =>
  log = server.log
  areaID = null
            
  resolveCoordinateToArea = (latitude, longitude) ->
    log.debug "Resolving coordinate #{latitude} / #{longitude} to area"
    url = 'http://feed.alertspro.meteogroup.com/AlertsPro/AlertsProPollService.php?method=lookupCoord&lat=' + latitude + '&lon=' + longitude
    result = await server.http.getJSON(url)
    if result.push? and result.length >= 0
      result = result[0].AREA_ID
      return result
    else
      throw new Error("Failed to resolve region for rain prediciton service")
          
  requestRainPrediction = ->
    throw new Error("Area not supported") unless areaID?
    url = 'http://weatherpro.consumer.meteogroup.com/weatherpro/RainService.php?method=getRainChart&areaID=' + areaID
    log.debug url
    result = await server.http.getJSON(url)
    throw new Error("No rain forecast available for the region") if !result?
    throw new Error("Unexpected API response: #{response}") unless result.intensity? and result.startMin? and result.endMin?
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
    return rain
        
  server.init = ->
    if server.config.areaID?
      areaID = server.config.areaID
    else
      result = await resolveCoordinateToArea(server.config.latitude, server.config.longitude)
      areaID = result
    
  server.handle 'rainforecast', (query) ->
    await requestRainPrediction()