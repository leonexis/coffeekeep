{ROMReader} = require './readers/rom'
{Area} = require './model/area'
{Room} = require './model/room'
{Mob} = require './model/mob'
{Item} = require './model/item'

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
            mob: 0
            area: 0
            item: 0

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
            vroom = currentArea.vrooms.get(data.id)
            if vroom?
                vroom.set data
                printStatus "Reloaded vRoom %c#{vroom.id}%. '%C#{vroom.get 'title'}%.'"
                #console.log "Reloaded vRoom #{room.id} '#{room.get 'title'}'"
                return

            vroom = new Room data
            printStatus "Adding vRoom %c#{vroom.id}%. '%C#{vroom.get 'title'}%.'"
            #console.log "Adding vRoom #{room.id} '#{room.get 'title'}'"
            currentArea.vrooms.add vroom

        rom.on 'mobile', (data) ->
            stats.mob++
            vmob = currentArea.vmobs.get(data.id)
            if vmob?
                vmob.set data
                printStatus "Reloaded vMob %c#{vmob.id}%. '%C#{vmob.get 'name'}%.'"
                return

            vmob = new Mob data
            printStatus "Adding vMob %c#{vmob.id}%. '%C#{vmob.get 'name'}%.'"
            currentArea.vmobs.add vmob

        rom.on 'item', (data) ->
            stats.item++
            vitem = currentArea.vitems.get(data.id)
            if vitem?
                vitem.set data
                printStatus "Reloaded vItem %c#{vitem.id}%. '%C#{vitem.get 'name'}%.'"
                return

            vitem = new Item data
            printStatus "Adding vItem %c#{vitem.id}%. '%C#{vitem.get 'name'}%.'"
            currentArea.vitems.add vitem

        rom.on 'done', ->
            #console.log "Imported last area, resetting it"
            resetArea currentArea
            printStatus("Done importing #{stats.area} areas, #{stats.room} rooms, #{stats.mob} mobs, #{stats.item} items")

        rom.read args[0]

