# TODO: Write
Log = require 'log'
_ = require 'underscore'

module.exports = (options, imports, register) ->
    _.defaults options,
        level: 'notice'
    
    log = new Log options.level
    register null,
        log: log