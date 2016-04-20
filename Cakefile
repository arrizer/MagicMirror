fs    = require 'fs'
spawn = require('child_process').spawn
app   = require './package.json'

task 'dev', 'Watch for changes, auto-compile client scripts and restart nodemon', ->
  run "nodemon -q --ext coffee,html,json,cson --exec coffee #{app.main} --dev"
  
run = (command, next) ->
  shell = spawn('bash', ['-c',command])
  console.log '$', command
  shell.stdout.pipe process.stdout
  shell.stderr.pipe process.stderr
  shell.on 'close', (code) ->
    next(code) if next?