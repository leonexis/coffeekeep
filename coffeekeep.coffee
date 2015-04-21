#!/usr/bin/env coffee
architect = require 'architect'
path = require 'path'
pkg = require './package.json'

exports.run = ->
    configFile = path.join __dirname, 'configs', 'default'
    optimist = require('optimist')
        .usage("Usage: $0 [options]")
        .options('c',
            'default': configFile
            alias: 'config'
            describe: "CoffeeKeep configuration file")
        .options('d',
            alias: 'debug'
            describe: "Enable debug logging (overrides verbose)")
        .options('v',
            alias: 'verbose'
            describe: "Enable verbose logging")

    argv = optimist.argv
    console.log "Loading configuration #{optimist.argv.c}"
    config = require optimist.argv.c

    # Set custom log level
    loglevel = null
    loglevel = 'info' if argv.v
    loglevel = 'debug' if argv.d

    if loglevel?
        for plugin in config
            if /coffeekeep\.log$/.test plugin.packagePath
                plugin.level = loglevel

    exports.createApp config, (err, app) ->
        throw err if err?
        console.log "Started CoffeeKeep #{pkg.version}!"

exports.createApp = (config, cb) ->
    config = architect.resolveConfig config, path.join __dirname, 'plugins'
    architect.createApp config, cb

if not module.parent?
    exports.run()
