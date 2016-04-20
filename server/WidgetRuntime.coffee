FileSystem = require 'fs'
Path = require 'path'
Async = require 'async'
Express = require 'express'
CoffeeScript = require 'coffee-script'
Widget = require './Widget'

log = require './Log'

module.exports = class WidgetRuntime
  constructor: (@widgetsDirectory, @clientScriptPath, @config) ->
    @widgets = {}
    @widgetInstances = []
    @router = Express.Router()
  
  load: (next) ->
    log.debug 'Loading available widgets from %s', @widgetsDirectory
    FileSystem.readdir @widgetsDirectory, (error, items) =>
      return log.error error if error?
      Async.eachSeries items, (item, next) =>
        path = Path.join @widgetsDirectory, item
        FileSystem.stat path, (error, stats) =>
          return next() if error?
          if stats.isDirectory() and Path.extname(path) is '.widget'
            @loadWidget path, next
          else
            next()
      , next
        
  loadWidget: (path, next) ->
    log.info 'Loading widget at %s', path
    widget = new Widget(path, @config.language)
    widget.load (error) =>
      if error?
        log.error error
      else
        @widgets[widget.info.name] = widget
        @router.use '/' + widget.info.name, widget.router
      next()
  
  startWidgets: (@config, next) ->
    counter = 1
    Async.eachSeries @config, (config, next) =>
      widget = @widgets[config.widget]
      if widget?
        instance = widget.instantiate(config.config, counter++)
        instance.init (error) => 
          @widgetInstances.push instance unless error?
          next error
      else
        next new Error('Unknown widget: ' + config.widget)
    , (error) =>
      @mount() unless error?
      next error
      
  mount: ->
    @router.get '/', (req, res) =>
      instances = []
      widgets = []
      for instance in @widgetInstances
        instances.push
          widget: instance.widget.info.name
          instanceID: instance.id
          config: instance.config
      for name,widget of @widgets
        widgets.push
          name: name
          template: widget.template
          strings: (if widget.strings? then JSON.stringify(widget.strings) else '{}')
      res.render 'client',
        widgets: widgets
        widget_instances: JSON.stringify(instances)
        config: JSON.stringify(@config)
        
    @router.get '/client.js', (req,res) =>
      FileSystem.readFile @clientScriptPath, (error, data) =>
        return res.status(500).send error if error?
        script = "var widgetFactories = {};\n"
        for name,widget of @widgets
          script += 'widgetFactories["' + name + '"] = ' + widget.clientScript + ";\n"
        try
          script += CoffeeScript.compile data.toString(), (header:no, bare:yes)
        catch error
          return res.status(500).send error
        res.set 'Content-Type', 'application/javascript'
        res.send script