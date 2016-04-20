
Winston = require 'winston'

logger = new Winston.Logger()
logger.add Winston.transports.File,
  level: 'info'
  filename: './Logs/log.log'
  maxsize: 5242880 #5MB
  maxFiles: 5
  colorize: no

logger.add Winston.transports.Console,
  level: 'debug'
  json: no
  colorize: yes
  
module.exports = logger