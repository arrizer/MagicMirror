Request = require 'request'
Async = require 'async'

round = (value, digits = 0) ->
  exp = Math.pow(10, digits)
  Math.round(value * exp) / exp

module.exports = (server) =>
  log = server.log
  config = server.config

  getCountryStats = (next) ->
    request = 
      url: "https://api.corona-zahlen.org/germany"
      json: yes
    log.info "Loading #{request.url}"
    Request request, (error, _, data) ->
      return next(error) if error?
      if data.error?
        log.error "Failed to load stats: #{JSON.stringify(data)}"
        return next(JSON.stringify(data))
      stats =
        label: "Deutschland"
        cases: data.cases
        dead: data.deaths
        recovered: data.recovered
        rvalue: round(data.r.rValue7Days.value, 2)
        incidence: round(data.weekIncidence, 1)
      next(null, stats)

  getDistrict = (district, next) ->
    # District IDs: https://api.corona-zahlen.org/districts
    request = 
      url: "https://api.corona-zahlen.org/districts/#{encodeURIComponent(district.id)}"
      json: yes
    log.info "Loading #{request.url}"
    Request request, (error, _, body) ->
      return next(error) if error?
      if body.error?
        log.error "Failed to load district data for #{district.id}: #{JSON.stringify(body)}"
        return next(JSON.stringify(body))
      data = body.data[district.id]
      result =
        label: district.label
        incidence: round(data.weekIncidence, 1)
      next(null, result)

  getDistricts = (next) ->
    return next(null, []) unless config.districts?
    Async.map config.districts, (district, done) ->
      getDistrict(district, done)
    , next

  getVaccinationProgress = (next) ->
    request =
      url: "https://impfdashboard.de/static/data/germany_vaccinations_timeseries_v2.tsv"
    Request request, (error, _, body) ->
      return next(error) if error?
      lines = body.split("\n")
      keys = lines.shift().split("\t")
      lines.pop()
      rows = lines.map (line) ->
        row = {}
        index = 0
        for value in line.split("\t")
          row[keys[index]] = value
          index++
        return row
      latestRow = rows.pop()
      result =
        progressFirstShot: parseFloat(latestRow['impf_quote_erst'])
        progressSecondShot: parseFloat(latestRow['impf_quote_voll'])
      next(null, result)

  loadStats = (next) ->
    getCountryStats (statsError, stats) ->
      getDistricts (districtsError, districts) ->
        getVaccinationProgress (vaccinationError, vaccinationProgress) ->
          result =
            stats: stats
            districts: districts
            vaccinationProgress: vaccinationProgress
          next(null, result)

  server.handle 'stats', (query, respond, fail) ->
    loadStats (error, items) ->
      if error?
        fail(error)
      else
        respond(items)