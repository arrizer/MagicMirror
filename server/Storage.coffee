FileSystem = require('fs')
Path = require 'path'

Log = require './Log'

module.exports = class Storage
  constructor: (@storageDir, filename) ->
    @file = Path.join(@storageDir, filename) + '.json'
    @log = new Log("Storage #{filename}")
    @keys = {}
    @load()

  load: ->
    return unless FileSystem.existsSync(@file)
    @log.info("Loading persistent data")
    data = FileSystem.readFileSync(@file)
    try
      json = JSON.parse(data)
      if json? and typeof json is 'object' and !Array.isArray(json)
        @keys = json
      else
        throw new Error("Unexpected persistent data. Not a top-level object")
    catch error
      @log.error("Failed to parse persistent data: #{error}")    

  save: ->
    @log.info("Saving persistent data")
    data = JSON.stringify(@keys)
    if !FileSystem.existsSync(@storageDir)
      FileSystem.mkdirSync(@storageDir, (recursive: yes))
    FileSystem.writeFile @file, data, (error) =>
      @log.error("Failed to save file: #{error}") if error?

  set: (key, value) =>
    @keys[key] = value
    @save()

  get: (key) =>
    return @keys[key]
