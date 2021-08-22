Express = require 'express'
ChildProcess = require 'child_process'

Log = require('./Log')
log = new Log("DisplayController")

module.exports = class DisplayController
  constructor: (@widgetsDirectory, @clientScriptPath, @config) ->
    @isOn = true
    @router = Express.Router()
    @router.get '/display-power', (req, res) =>
      res.send(if @isOn then '1' else '0')
    @router.put '/display-power', (req, res) =>
      command = req.query.on
      return res.status(400).send("URL parameter 'on' must be either '1' or '0'") unless command? and command is '1' or command is '0'
      @setOn (command is '1'), (error) =>
        return res.status(500).send("Command failed") if error?
        res.status(200).send("Set display power to #{command}")

  setOn: (isOn, next) ->
    command = "vcgencmd display_power #{if isOn then '1' else '0'}"
    ChildProcess.exec command, (error) =>
      if error?
        log.error "Failed to run command '#{command}': #{error}"
      else
        @isOn = isOn
      next(error)