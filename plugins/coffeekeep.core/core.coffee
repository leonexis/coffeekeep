_ = require 'underscore'
events = require 'events'
async = require 'async'
engine = require './engine'
terminal = require './terminal'

module.exports = (options, imports, register) ->
    {log, world, commands, interpreter} = imports
    _.defaults options,
        host: process.env.IP ? '0.0.0.0'
        port: process.env.PORT ? 8080
        telnetPort: process.env.TELNET_PORT ? 5555

    mud = new engine.MudService options, imports
    app = null
    server = null
    async.series [
        (cb) ->
            commands.loadDirectory __dirname + '/commands'
            cb null
        (cb) ->
            require('./app').setup options, imports, (err, app_) ->
                throw err if err?
                app = app_
                cb null
        (cb) ->
            server = app.get 'server'
            require('./terminal').setup options, {server:server, mud:mud}, cb
    ],  (err) ->
            register err if err?
            register null,
                mud: mud
                site:
                    app: app
                    server: server