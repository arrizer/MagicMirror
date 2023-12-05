CoffeeScript = require 'coffeescript'
FileSystem = require('fs').promises
KoaRouter = require 'koa-router'
Path = require 'path'
Widget = require './Widget'

Log = require './Log'

module.exports = class WidgetRuntime
  constructor: (@widgetsDirectory, @clientScriptPath, @storagePath, @config) ->
    @log = new Log("WidgetRuntime")
    @widgets = {}
    @widgetInstances = []
    @router = new KoaRouter()
  
  load: ->
    @log.debug "Loading available widgets from #{@widgetsDirectory}"
    items = await FileSystem.readdir(@widgetsDirectory)
    for item in items
      path = Path.join @widgetsDirectory, item
      stats = await FileSystem.stat(path)
      if stats.isDirectory() and Path.extname(path) is '.widget'
        await @loadWidget(path)
        
  loadWidget: (path) ->
    @log.info "Loading widget at #{path}"
    widget = new Widget(path, @config.language)
    try
      await widget.load()
      @widgets[widget.info.name] = widget
      @router.use '/' + widget.info.name, widget.router.routes()
    catch error
      @log.error "Error loading widget: #{error}"
  
  startWidgets: (widgetConfigs) ->
    instanceCounts = {}
    for config in widgetConfigs
      widget = @widgets[config.widget]
      throw new Error("Unknown widget: #{config.widget}") unless widget?
      id = instanceCounts[config.widget] or 0
      instance = widget.instantiate(config.config, id, @storagePath)
      instanceCounts[config.widget] = id + 1
      @router.use '/' + instance.id, instance.router.routes()
      await instance.init()
      @widgetInstances.push(instance)
    @mount()

  compileClientScript: ->
    data = await FileSystem.readFile(@clientScriptPath)
    script = "var widgetFactories = {};\n"
    for name,widget of @widgets
      script += 'widgetFactories["' + name + '"] = ' + widget.clientScript + ";\n"
    script += CoffeeScript.compile(data.toString(), (header:no, bare:yes))
    return script
      
  mount: ->
    @router.get '/', (ctx) =>
      clientScript = await @compileClientScript()
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
      ctx.render 'client',
        widgets: widgets
        widget_instances: JSON.stringify(instances)
        config: JSON.stringify(@config)
        client: clientScript
