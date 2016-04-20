#!/usr/bin/env coffee

console.log " "

Server = require './server/Server'
Path = require 'path'

# Load config
config = require('./config.json')
config.path = __dirname

server = new Server(config)
server.start()