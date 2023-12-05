CoffeeScript = require 'coffeescript'
FileSystem = require('fs').promises
KoaRouter = require 'koa-router'
KoaStatic = require 'koa-static'
Path = require 'path'

Log = require('./Log')
WidgetInstance = require './WidgetInstance'

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

  instantiate: (config, instanceID, storagePath) ->
    new WidgetInstance(@, config, instanceID, storagePath)
