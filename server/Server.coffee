
Express      = require 'express'
BodyParser   = require 'body-parser'
Static       = require 'serve-static'
HTTP         = require 'http'
Path         = require 'path'
FileSystem   = require 'fs'
Hogan        = require 'hogan-express'

WidgetRuntime = require './WidgetRuntime'
DisplayController = require './DisplayController'

log = require './Log'

module.exports = class Server
  DEFAULT_PORT = 8080

  constructor: (@config) ->
    log.debug 'Setting up server...'
    @parseArguments()
    app = Express()
    app.enable 'trust proxy'
    app.disable 'x-powered-by'
    app.set "port", (@config.port or DEFAULT_PORT)
    app.set "views", Path.join(@config.path, 'server', 'client')
    app.set 'view engine', 'html'
    app.enable 'view cache'
    app.engine 'html', Hogan
    
    # Middleware
    app.use BodyParser.json()
    app.use Static(Path.join(@config.path, 'server', 'static'))
    @app = app

  parseArguments: ->
    @args = {}
    for arg in process.argv
      if arg.startsWith('--')
        components = arg.split('=')
        key = components[0].substring(2)
        value = if components.length == 2 then components[1] else true
        @args[key] = value
        log.debug "Launch argument: #{key}=#{value}"      
  
  start: (next) ->
    @displayController = new DisplayController()
    @runtime = new WidgetRuntime(Path.join(@config.path, 'widgets'), Path.join(@config.path, 'server', 'client', 'client.coffee'), @config)
    @runtime.load =>
      widgets = @config.widgets
      if @args['only-widget']?
        widgets = widgets.filter((item) => item.widget == @args['only-widget'])
      @runtime.startWidgets widgets, (error) =>
        if error?
          log.error "Failed to start widgets: %s", error
          next error if next?
        else
          @app.use @runtime.router
          @app.use @displayController.router
          @startServer next
        
  startServer: (next) ->
    HTTP.createServer(@app).listen @app.get("port"), (error) =>
      if error?
        log.error "Failed to start server: %s", error
      else
        log.info "Widget-Server ready on port %d", @app.get("port")
      next() if next?