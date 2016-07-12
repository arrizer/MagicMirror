SQLite3 = require 'sqlite3'
FileSystem = require 'fs'
ChildProcess = require 'child_process'

TEMP_FILE = "/tmp/things.db"

module.exports = (server) =>
  log = server.log
    
  server.init = (next) ->
    next()
    
  server.handle 'todos', (query, respond, fail) ->
    ChildProcess.exec "cp -R \"#{server.config.databaseFile}\" \"#{TEMP_FILE}\"", (error) ->
      return fail(error) if error?
      database = new SQLite3.Database(TEMP_FILE)
      database.serialize ->
        database.all 'SELECT ZTITLE, ZSTARTDATE FROM ZTHING WHERE ZSTATUS = 0 AND ZSTART = 1 AND ZFOCUSLEVEL1 = 0', (error, rows) ->
          return fail(error) if error?
          todos = []
          for row in rows
            todos.push
              title: row.ZTITLE
              today: row.ZSTARTDATE?
          respond(todos)