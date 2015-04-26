terminal = require 'term.js'
io = require 'socket.io'
express = require 'express'
http = require 'http'
exports.app = app = express()
exports.httpServer = server = http.createServer(app)

exports.setup = (options, imports, cb) ->
    {log, world} = imports
    _log = new log.Logger "coffeekeep.core:app"
    app.set 'view engine', 'jade'
    app.set 'views', __dirname + '/views'

    app.use express.logger()

    app.use terminal.middleware()

    app.get '/', (req, res) ->
        res.redirect '/client'

    app.get '/world', (req, res) ->
        area = world.areas.first()
        res.render 'world', world: world

    app.get '/world/:areaid', (req, res) ->
        area = world.areas.get req.params.areaid
        res.render 'area', area: area

    app.get '/world/:areaid/:roomid', (req, res) ->
        # Rooms
        area = world.areas.get req.params.areaid
        room = area.rooms.get req.params.roomid
        res.render 'room', room: room

    app.get '/client', (req, res) ->
        res.render 'mudClient'

    app.use express.directory "#{__dirname}/../public"
    app.use express.static "#{__dirname}/../public"

    app.set 'server', server

    try
        server.listen options.port, options.host, ->
            _log.notice "Started web service at #{options.host}:#{options.port}"
            cb null, app
    catch err
        _log.error "Error while starting web services:", err
        return cb err
