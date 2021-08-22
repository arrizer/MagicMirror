FileSystem = require 'fs'
Path = require 'path'
Express = require 'express'
CoffeeScript = require 'coffeescript'
Static       = require 'serve-static'

Log = require('./Log')

module.exports = class Widget
  constructor: (@path, @language) ->
    @log = new Log("Widget #{@path}")
    @router = Express.Router()
  
  load: (next) ->
    @readInfo (error) =>
      return next error if error?
      @readStrings (error) =>
        return next error if error?      
        @compileClient (error) =>
          return next new Error('Failed to compile widget.coffee: ' + error) if error?
          @loadTemplate (error) =>
            return next error if error?
            @mountStaticResources =>
              @createServerFactory =>
                next()

  readInfo: (next) ->
    @log.debug 'Parsing info.json'
    infoFilePath = Path.join @path, 'info.json'
    FileSystem.readFile infoFilePath, (error, data) =>
      return next new Error("Failed to read info.json file: " + error) if error?
      try
        @info = JSON.parse data.toString()
      catch error
        return next new Error("Failed to parse info.json file: " + error)
      return next new Error("Key 'name' missing in info.json file") unless @info.name? and typeof @info.name is 'string'
      @router.get '/', (req,res) => res.json @info
      next()
      
  readStrings: (next) ->
    @log.debug 'Parsing strings.json'
    infoFilePath = Path.join @path, 'strings.json'
    FileSystem.readFile infoFilePath, (error, data) =>
      return next() if error?
      allStrings = {}
      try
        allStrings = JSON.parse(data.toString())
        @strings = allStrings[@language]
      catch error
        return next new Error("Failed to parse strings.json file: " + error)
      if allStrings.en?
        for key,value of allStrings.en
          @strings[key] = value unless @strings[key]?
      next()
      
  compileClient: (next) ->
    @log.debug 'Compiling widget.coffee'
    path = Path.join @path, 'widget.coffee'
    FileSystem.readFile path, (error, data) =>
      return next new Error("Failed to read widget.coffee file: " + error) if error?
      try
        @clientScript = CoffeeScript.compile data.toString(),
          header:no, 
          bare:yes 
      catch error
        return next error
      next()
      
  loadTemplate: (next) ->
    @log.debug 'Loading template.html'
    path = Path.join @path, 'template.html'
    FileSystem.readFile path, (error, data) =>
      return next new Error("Failed to read template.html file: " + error) if error?
      @template = data.toString()
      next()
      
  mountStaticResources: (next) ->
    path = Path.join @path, 'resources'
    FileSystem.stat path, (error, stats) =>
      unless error?
        @router.use '/resources', Static(path)
      next()

  createServerFactory: (next) ->
    path = Path.join @path, 'server.coffee'
    FileSystem.stat path, (error, stats) =>
      if !error? and stats.isFile()
        @serverFactory = require(@path + '/server') 
      next()
      
  instantiate: (config, instanceID) ->
    instance = new WidgetInstance(@, config, instanceID)
    @router.use '/' + instanceID, instance.router
    return instance
    
class WidgetInstance
  constructor: (@widget, @config, id) ->
    @id = @widget.info.name + '/' + id
    @log = new Log("Widget #{@id}")
    @log.debug "Creating widget instance"
    @endpoints = {}
    @router = Express.Router()
    @server =
      log:
        debug: (message) => @log.debug(message.toString())
        info: (message) => @log.info(message.toString())
        error: (message) => @log.error(message.toString())
      config: @config
      handle: (endpoint, handler) =>
        @endpoints[endpoint] = handler
      string: (key, placeholders...) => 
        string = @widget.strings[key]
        index = 1
        string = string.replace '%' + index++, placeholder for placeholder in placeholders
        return string
      init: (next) ->
        next()
    try
      @widget.serverFactory @server if @widget.serverFactory?
    catch error
      return @log.error "Error while creating widget instance: #{error}"
    @mount()
    
  init: (next) ->
    @log.debug "Initializing widget instance"
    @server.init (error) =>
      if error?
        @log.error "Failed to initialized widget instance #{error}"
        next error
      else
        @log.debug "Successfully initialized widget instance"
        next()
        
  mount: ->
    for endpoint, handler of @endpoints
      path = @id + '/' + endpoint
      @log.debug "Mounting server-handler: #{path}"
      @router.get '/' + endpoint, (req, res) =>
        @log.debug "Incoming endpoint request for #{path}, parameters: #{JSON.stringify(req.query)}"
        onResult = (result) => 
          @log.debug "Responding to #{path} with response:\n#{JSON.stringify(result, null, 2)}"
          res.json (success: yes, response: result)
        onError = (error) => 
          @log.error "Responding to #{path} with error: #{error}"
          res.json (success: no, error: "#{error}")
        handler req.query, onResult, onError