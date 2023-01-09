CoffeeScript = require 'coffeescript'
FileSystem = require('fs').promises
KoaRouter = require 'koa-router'
KoaSend = require 'koa-send'
KoaStatic = require 'koa-static'
Path = require 'path'

Log = require('./Log')

module.exports = class Widget
  constructor: (@path, @language) ->
    @log = new Log("Widget #{@path}")
    @router = new KoaRouter()
  
  load: ->
    await @readInfo()
    await @readStrings()
    await @compileClient()
    await @loadTemplate()
    await @mountStaticResources()
    await @createServerFactory()

  readInfo: ->
    @log.debug 'Parsing info.json'
    infoFilePath = Path.join(@path, 'info.json')
    data = await FileSystem.readFile(infoFilePath)
    try
      @info = JSON.parse data.toString()
    catch error
      throw new Error("Failed to parse info.json file: " + error)
    unless @info.name? and typeof @info.name is 'string'
      throw new Error("Key 'name' missing in info.json file")
    @router.get '/', (ctx) => 
      ctx.body = @info

  readStrings: ->
    @log.debug 'Parsing strings.json'
    infoFilePath = Path.join(@path, 'strings.json')
    data = await FileSystem.readFile infoFilePath
    allStrings = {}
    try
      allStrings = JSON.parse(data.toString())
      @strings = allStrings[@language]
    catch error
      throw new Error("Failed to parse strings.json file: " + error)
    if allStrings.en?
      for key,value of allStrings.en
        @strings[key] = value unless @strings[key]?

  compileClient: ->
    @log.debug 'Compiling widget.coffee'
    path = Path.join(@path, 'widget.coffee')
    data = await FileSystem.readFile(path)
    @clientScript = CoffeeScript.compile(data.toString(), (header:no, bare:yes))

  loadTemplate: ->
    @log.debug 'Loading template.html'
    path = Path.join(@path, 'template.html')
    data = await FileSystem.readFile(path)
    @template = data.toString()

  mountStaticResources: ->
    path = Path.join(@path, 'resources')
    try
      await FileSystem.stat(path)
      @log.debug "Mounting static resources at: #{path}"
      @router.get '/resources/:path*', (ctx, next) =>
        ctx.path = ctx.path.split('/')[3..].join('/')
        KoaStatic(path)(ctx, next)

  createServerFactory: ->
    path = Path.join(@path, 'server.coffee')
    try
      stats = await FileSystem.stat(path)
      if stats.isFile()
        @serverFactory = require(@path + '/server') 

  instantiate: (config, instanceID) ->
    new WidgetInstance(@, config, instanceID)

class WidgetInstance
  constructor: (@widget, @config, id) ->
    @id = @widget.info.name + '/' + id
    @log = new Log("Widget #{@id}")
    @log.debug "Creating widget instance"
    @endpoints = {}
    @router = new KoaRouter()
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
    
  init: ->
    @log.debug "Initializing widget instance"
    await new Promise (resolve, reject) =>
      @server.init (error) =>
        if error?
          @log.error "Failed to initialized widget instance #{error}"
          reject(error)
        else
          @log.debug "Successfully initialized widget instance"
          resolve()
        
  mount: ->
    for endpoint, handler of @endpoints
      path = @id + '/' + endpoint
      @log.debug "Mounting server-handler: #{path}"
      @router.get '/' + endpoint, (ctx) =>
        @log.debug "Incoming endpoint request for #{path}, parameters: #{JSON.stringify(ctx.query)}"
        try
          result = await new Promise (resolve, reject) =>
            handler ctx.query, resolve, reject
          @log.debug "Responding to #{path} with response:\n#{JSON.stringify(result, null, 2)}"
          ctx.body = (success: yes, response: result)
        catch error
          @log.error "Responding to #{path} with error: #{error}"
          ctx.body = (success: no, error: "#{error}")