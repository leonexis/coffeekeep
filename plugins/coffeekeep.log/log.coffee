log = require 'npmlog'
_ = require 'underscore'

class Logger
    constructor: (@prefix) ->
    log: log
    _log: (level, args...) -> log.log level, _.result(@, 'prefix'), args...
    silly: (args...) -> @_log 'silly', args...
    debug: (args...) -> @_log 'debug', args...
    verbose: (args...) -> @_log 'verbose', args...
    info: (args...) -> @_log 'info', args...
    notice: (args...) -> @_log 'notice', args...
    warn: (args...) -> @_log 'warn', args...
    error: (args...) -> @_log 'error', args...

log.Logger = Logger
log.addLevel 'debug', 500, {fg: 'grey', bg: 'black'}, 'dbug'
log.addLevel 'notice', 3000, {fg: 'green', bg: 'black'}, 'note'

module.exports = (options, imports, register) ->
    _.defaults options,
        level: 'info'

    log.level = options.level
    log.info 'coffeekeep.log', 'Current log level: %s', log.level
    register null,
        log: log
