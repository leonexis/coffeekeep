{ROMReader} = require './readers/rom'
{Area} = require './model/area'
{Room} = require './model/room'
{Mob} = require './model/mob'

new Command
    name: 'import'
    acl: '-all +sysop'
    description: "Imports an area from a file."
    help: "Usage: import <file>"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if args.length < 1
            mob.print "You must specify a file"

        currentArea = null

        rom = new ROMReader()

        rom.on 'area', (data) ->
            currentArea = new Area data
            world.areas.add currentArea
            mob.print "Creating area %c#{currentArea.id}%."

        rom.on 'room', (data) ->
            room = new Room data
            mob.print "Adding room %c#{room.id}%. '%C#{room.get 'title'}%.'"
            console.log "Adding room #{room.id} '#{room.get 'title'}'"
            currentArea.rooms.add room

        rom.on 'done', ->
            mob.print "Done."

        rom.read args[0]

