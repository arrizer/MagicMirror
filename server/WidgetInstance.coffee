KoaRouter = require 'koa-router'
Path = require 'path'

Log = require './Log'
HTTPClient = require './HTTPClient'

module.exports = class WidgetInstance
  constructor: (@widget, @config, id) ->
    @id = @widget.info.name + '/' + id
    @log = new Log("Widget #{@id}")
    @log.debug "Creating widget instance"
    @endpoints = {}
    @router = new KoaRouter()
    @httpClient = new HTTPClient(@log)
    @server =
      log:
        debug: (message) => @log.debug(message.toString())
        info: (message) => @log.info(message.toString())
        error: (message) => @log.error(message.toString())
      config: @config
      http: @httpClient
      handle: (endpoint, handler) =>
        @endpoints[endpoint] = handler
      string: (key, placeholders...) => 
        string = @widget.strings[key]
        index = 1
        string = string.replace '%' + index++, placeholder for placeholder in placeholders
        return string
      init: ->
        Promise.resolve()
    try
      @widget.serverFactory @server if @widget.serverFactory?
    catch error
      return @log.error "Error while creating widget instance: #{error}"
    @mount()
    
  init: ->
    @log.debug "Initializing widget instance"
    try
      await @server.init()
      @log.debug "Successfully initialized widget instance"
    catch error
      @log.error "Failed to initialized widget instance #{error}"
      throw error

  mount: ->
    for endpoint, handler of @endpoints
      path = @id + '/' + endpoint
      @log.debug "Mounting server-handler: #{path}"
      @router.get '/' + endpoint, (ctx) =>
        @log.debug "Incoming endpoint request for #{path}, parameters: #{JSON.stringify(ctx.query)}"
        try
          result = await handler()
          @log.debug "Responding to #{path} with response:\n#{JSON.stringify(result, null, 2)}"
          ctx.body = (success: yes, response: result)
        catch error
          @log.error "Responding to #{path} with error: #{error}"
          ctx.body = (success: no, error: "#{error}")

  