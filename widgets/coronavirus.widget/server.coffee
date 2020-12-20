Request = require 'request'
Async = require 'async'

module.exports = (server) =>
  log = server.log
  config = server.config

  getToken = (next) ->
    Request (url: "https://coronavirus.app/map"), (error, response, body) ->
      return next(error) if error?
      auth =
        token: /data-a="(.*?)"/.exec(body)[1]
        header: /data-b="(.*?)"/.exec(body)[1]
        date: /data-c="(.*?)"/.exec(body)[1]
      next(null, auth)

  getPlaces = (next) ->
    return next(null, []) unless config.places?
    getToken (error, auth) ->
      return next(error) if error?
      headers = {}
      headers[auth.header] = auth.token
      headers['x-date-req'] = auth.date
      request = 
        url: "https://coronavirus.app/get-places"
        headers: headers
        json: yes
      Request request, (error, _, body) ->
        return next(error) if error?
        places = body.data
        items = []
        for placeConfig in config.places
          item =
            label: placeConfig.label
            infected: 0
            sick: 0
            dead: 0
            recovered: 0
          for place in places
            continue if placeConfig.country? and (place.country isnt placeConfig.country)
            item.infected += place.infected
            item.sick += place.sick
            item.dead += place.dead
            item.recovered += place.recovered
          items.push(item)
        next(null, items)

  getCounty = (county, next) ->
    # Find RKI county IDs here: 
    # https://npgeo-corona-npgeo-de.hub.arcgis.com/datasets/917fc37a709542548cc3be077a786c17_0/data?geometry=-10.085%2C46.211%2C32.103%2C55.839&orderBy=OBJECTID&selectedAttribute=BL
    request = 
      url: "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query"
      qs:
        objectIds: county.id
        outFields: '*'
        returnGeometry: false
        returnCentroid: false
        f: 'pjson'
      json: yes
    Request request, (error, _, body) ->
      return next(error) if error?
      attributes = body.features[0].attributes
      result =
        label: county.label
        incidence: Math.round(attributes.cases7_per_100k)
      next(null, result)

  getCounties = (next) ->
    return next(null, []) unless config.rki_counties?
    Async.map config.rki_counties, (county, next) ->
      getCounty(county, next)
    , next

  loadStats = (next) ->
    getPlaces (placesError, places) ->
      getCounties (countiesError, counties) ->
        error = placesError or countiesError
        next(error) if error?
        result =
          places: places
          counties: counties
        next(null, result)

  server.handle 'stats', (query, respond, fail) ->
    loadStats (error, items) ->
      if error?
        fail(error)
      else
        respond(items)