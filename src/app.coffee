express = require 'express'
exports.app = app = express()

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/../views'

app.use express.logger()

app.get '/', (req, res) ->
    res.redirect '/map'

app.get '/map', (req, res) ->
    world = app.get 'coffeekeep world'
    area = world.areas.get 'school.are'
    res.render 'area', area: area

app.get '/map/:roomid', (req, res) ->
    # Rooms
    world = app.get 'coffeekeep world'
    area = world.areas.get 'school.are'
    room = area.rooms.get req.params.roomid
    res.render 'room', room: room

app.use express.directory "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"
