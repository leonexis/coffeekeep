express = require 'express'
exports.app = app = express()

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/../views'

app.use express.logger()

app.get '/', (req, res) ->
    res.redirect '/world'

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

app.use express.directory "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"
