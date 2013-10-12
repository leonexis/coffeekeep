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
        currentSection = null
        stats = 
            room: 0
            area: 0
        
        printStatus = (status) =>
            mob.print "\x1b[1A\x1b[2K#{status}"
        
        updateProgress = (task, total, action) =>
            printStatus "Area reset: [#{task}/#{total}] #{action}"
        
        resetArea = (area) ->
            area.on 'progress:reset', updateProgress
            area.reset()
            area.off 'progress:reset', updateProgress
            printStatus "Done importing area %c#{area.id}%."
        
        mob.print ''

        rom = new ROMReader()

        rom.on 'area', (data) ->
            stats.area++
            if currentArea?
                console.log "Starting new area, resetting previous area."
                resetArea currentArea
                
            currentArea = world.areas.get data.id
            if currentArea?
                currentArea.set data
                printStatus "Reloading area %c#{currentArea.id}%."
                mob.print ''
                return

            currentArea = new Area data
            world.areas.add currentArea
            printStatus "Creating area %c#{currentArea.id}%."
            mob.print ''

        rom.on 'room', (data) ->
            stats.room++
            room = currentArea.vrooms.get(data.id)
            if room?
                room.set data
                printStatus "Reloaded vRoom %c#{room.id}%. '%C#{room.get 'title'}%.'"
                #console.log "Reloaded vRoom #{room.id} '#{room.get 'title'}'"
                return

            room = new Room data
            printStatus "Adding vRoom %c#{room.id}%. '%C#{room.get 'title'}%.'"
            #console.log "Adding vRoom #{room.id} '#{room.get 'title'}'"
            currentArea.vrooms.add room

        rom.on 'done', ->
            #console.log "Imported last area, resetting it"
            resetArea currentArea
            printStatus "Done importing #{stats.area} areas, #{stats.room} rooms"

        rom.read args[0]

