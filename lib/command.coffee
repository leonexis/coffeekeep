optimist = require 'optimist'
{World} = require './model/world'
{Area} = require './model/area'
{Room} = require './model/room'
{Mob} = require './model/mob'
{User} = require './model/user'
{app, httpServer} = require './app'

exports.run = ->
    {ROMReader} = require './readers/rom'
    {Model, Collection} = require './model'
    sqlitePlugin = require './core/storage/sqlite' 
    sqlitePlugin.enable Model, Collection
    
    world = app.get 'coffeekeep world'
    world.users.add
        name: 'player'
        
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
    world.commands.loadDirectory __dirname + '/core/commands'
    do world.users.fetch
    
if not module.parent?
    exports.run()