FileSystem = require 'fs'
Koa = require 'koa'
KoaBody = require('koa-body').koaBody
KoaStatic = require 'koa-static'
KoaViews = require 'koa-views'
Path = require 'path'

DisplayController = require './DisplayController'
Log = require './Log'
WidgetRuntime = require './WidgetRuntime'

module.exports = class Server
  DEFAULT_PORT = 8080

  constructor: (@config) ->
    @log = new Log("Server")
    @log.debug 'Setting up server...'
    @parseArguments()
    @app = new Koa()
    @app.use KoaViews(Path.join(@config.path, 'server', 'client'), (map: (html: 'mustache')))
    @app.use KoaStatic(Path.join(@config.path, 'server', 'static'))
    @app.use KoaBody()

  parseArguments: ->
    @args = {}
    for arg in process.argv
      if arg.startsWith('--')
        components = arg.split('=')
        key = components[0].substring(2)
        value = if components.length == 2 then components[1] else true
        @args[key] = value
        @log.debug "Launch argument: #{key}=#{value}"      
  
  start: ->
    @displayController = new DisplayController()
    @runtime = new WidgetRuntime(Path.join(@config.path, 'widgets'), Path.join(@config.path, 'server', 'client', 'client.coffee'), Path.join(@config.path, 'storage'), @config)
    onlyWidget = @args['only-widget']
    await @runtime.load(onlyWidget)
    widgets = @config.widgets
    if onlyWidget?
      widgets = widgets.filter((item) => item.widget == onlyWidget)
    try
      await @runtime.startWidgets(widgets)
    catch error
      @log.error "Failed to start widgets. Shutting down"
      process.exit(128)
      return
    @app.use @runtime.router.routes()
    @app.use @displayController.router.routes()
    @startServer()
        
  startServer: ->
    port = @config.port or DEFAULT_PORT
    @app.listen(port)
    @log.info "Widget-Server ready on port #{port}"
