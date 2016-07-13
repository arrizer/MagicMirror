SQLite3 = require 'sqlite3'
FileSystem = require 'fs'
ChildProcess = require 'child_process'

TEMP_FILE = "/tmp/things.db"
SQL_QUERY = "SELECT ZTITLE, ZSTARTDATE FROM ZTHING WHERE ZSTATUS = 0 AND ZSTART = 1 AND ZFOCUSLEVEL1 = 0"

module.exports = (server) =>
  log = server.log
  
  run = (command, callback) ->
    if server.config.remoteUser? and server.config.remoteHost?
      ChildProcess.exec "ssh #{server.config.remoteUser}@#{server.config.remoteHost} '#{command}'", callback
    else
      ChildProcess.exec command, callback
      
  queryDatabase = (query, next) ->
    run "cp \"#{server.config.databaseFile}\" \"#{TEMP_FILE}\"; sqlite3 \"#{TEMP_FILE}\" \"#{query}\"", (error, stdout, stderr) ->
      return next(error) if error?
      rows = stdout.split("\n").map (row) -> row.split('|')
      rows.pop()
      next(null, rows)
          
  server.init = (next) ->
    next()
    
  server.handle 'todos', (query, respond, fail) ->
    queryDatabase SQL_QUERY, (error, rows) ->
      todos = rows.map (row) ->
        todo = {}
        todo.title = row[0]
        todo.today = row[1] isnt ''
        return todo
      return fail(error) if error?
      respond(todos)