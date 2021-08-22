
CLIColor   = require 'cli-color'

LEVELS = [
  emoji: '📣'
  label: 'V'
  labelColors: ['magentaBright']
  textColors: ['blackBright']
,
  emoji: '🐞'
  label: 'D'
  labelColors: ['cyan']
  textColors: ['blackBright']
,
  emoji: 'ℹ️ '
  label: 'I'
  labelColors: ['cyan']
  textColors: []
,
  emoji: '⚠️ '
  label: 'W'
  labelColors: ['black','bgYellow']
  textColors: ['yellow']
,
  emoji: '❌'
  label: 'E'
  labelColors: ['red']
  textColors: ['red']
,
  emoji: '🔴'
  label: 'F'
  labelColors: ['white','bgRedBright']
  textColors: ['red']
]

module.exports = class Log
  @_log: (level, module, message) ->
    level = LEVELS[level]
    line = ''
    line += @colorize("#{new Date().toISOString()}", 'blackBright')
    line += " "
    line += level.emoji
    line += " "
    line += @colorize("[#{module}]", 'white')
    line += " "
    line += @colorize(message.toString(), level.textColors...)
    console.error line

  @colorize: (string, colors...) ->
    return string if !colors? or colors.length == 0
    chain = CLIColor
    chain = chain[color] for color in colors
    return chain(string)

  constructor: (@module) ->

  verbose: (message) ->
    @log(0, message)

  debug: (message) ->
    @log(1, message)

  info: (message) ->
    @log(2, message)

  warning: (message) ->
    @log(3, message)

  error: (message) ->
    @log(4, message)

  fatal: (message) ->
    @log(5, message)

  log: (level, message) ->
    @constructor._log(level, @module, message)

  bell: ->
    console.error '\u0007'
