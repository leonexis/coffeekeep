optimist = require 'optimist'
{World} = require './model/world'
{Area} = require './model/area'
{Room} = require './model/room'
{app} = require './app'

exports.run = ->
    {ROMReader} = require './readers/rom'
    
    world = new World()
    currentArea = null
    
    rom = new ROMReader()
    
    rom.on 'area', (data) ->
        currentArea = new Area data
        world.areas.add currentArea
    
    rom.on 'room', (data) ->
        room = new Room data
        currentArea.rooms.add room
    
    rom.on 'done', ->
        app.set 'coffeekeep world', world
        port = process.env.PORT ? 5555
        app.listen port
        console.log "Listening on port #{port}"
    
    rom.read __dirname + '/../areas/school.are'
    
if not module.parent?
    exports.run()