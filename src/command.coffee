optimist = require 'optimist'
{World} = require './model/world'
{Area} = require './model/area'
{Room} = require './model/room'
{app, httpServer} = require './app'

exports.run = ->
    {ROMReader} = require './readers/rom'
    
    world = app.get 'coffeekeep world'
    currentArea = null
    
    rom = new ROMReader()
    
    rom.on 'area', (data) ->
        currentArea = new Area data
        world.areas.add currentArea
    
    rom.on 'room', (data) ->
        room = new Room data
        room.area = currentArea
        currentArea.rooms.add room
    
    rom.on 'done', ->
        app.set 'coffeekeep world', world
        port = process.env.PORT ? 5555
        httpServer.listen port
        console.log "Listening on port #{port}"
    
    rom.read optimist.argv._[0]
    
if not module.parent?
    exports.run()