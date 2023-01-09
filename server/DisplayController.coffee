ChildProcess = require 'child_process'
KoaRouter = require 'koa-router'

Log = require('./Log')

module.exports = class DisplayController
  constructor: (@widgetsDirectory, @clientScriptPath, @config) ->
    @log = new Log("DisplayController")
    @isOn = true
    @router = new KoaRouter()
    @router.get '/display-power', (ctx) =>
      ctx.body = (if @isOn then '1' else '0')
    @router.put '/display-power', (ctx) =>
      isOn = ctx.query.on
      ctx.assert(isOn is '1' or isOn is '0', 400, "URL parameter 'on' must be either '1' or '0'")
      await @setOn (isOn is '1')
      res.status = 200
      res.body "Set display power to #{isOn}"

  setOn: (isOn) ->
    command = "vcgencmd display_power #{if isOn then '1' else '0'}"
    new Promise (resolve, reject) =>
      ChildProcess.exec command, (error) =>
        if error?
          @log.error "Failed to run command '#{command}': #{error}"
          reject(error)
        else
          @isOn = isOn
          resolve()