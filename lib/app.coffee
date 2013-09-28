terminal = require 'term.js'
io = require 'socket.io'
express = require 'express'
http = require 'http'
{MudClientService} = require './terminal'
{MudService} = require './engine'
{World} = require './model/world'
exports.app = app = express()
exports.httpServer = server = http.createServer(app)

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'

app.use express.logger()

app.use terminal.middleware()

app.get '/', (req, res) ->
    res.redirect '/client'

app.get '/world', (req, res) ->
    world = app.get 'coffeekeep world'
    area = world.areas.first()
    res.render 'world', world: world
    
app.get '/world/:areaid', (req, res) ->
    world = app.get 'coffeekeep world'
    area = world.areas.get req.params.areaid
    res.render 'area', area: area

app.get '/world/:areaid/:roomid', (req, res) ->
    # Rooms
    world = app.get 'coffeekeep world'
    area = world.areas.get req.params.areaid
    room = area.rooms.get req.params.roomid
    res.render 'room', room: room

app.get '/client', (req, res) ->
    res.render 'mudClient'

app.use express.directory "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"