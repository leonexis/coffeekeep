_ = require 'underscore'
events = require 'events'
async = require 'async'
engine = require './engine'
terminal = require './terminal'

module.exports = (options, imports, register) ->
    {log, world} = imports
    _.defaults options,
        host: process.env.IP ? '0.0.0.0'
        port: process.env.PORT ? 8080
        telnetPort: process.env.TELNET_PORT ? 5555

    mud = new engine.MudService world
    app = null
    server = null
    async.waterfall [
        (cb) -> require('./app').setup options, imports, cb
        (app, cb) -> 
            app = app
            server = app.get 'server'
            require('./terminal').setup options, {server:server, mud:mud}, cb
    ],  (err) ->
            register err if err?
            register null,
                mud: mud
                site: 
                    app: app
                    server: server