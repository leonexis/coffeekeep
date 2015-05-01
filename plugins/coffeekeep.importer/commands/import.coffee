fs = require 'fs'
util = require 'util'

new Command
  name: 'import'
  acl: '-all +sysop'
  description: "Imports an area from a file."
  help: "Usage: import <file>"
  consumes: ['importer', 'model']
  action: (context, request, callback) ->
    {mob, room, world, area} = context
    {verb, args} = request
    {importer, model} = imports
    if args.length < 1
      mob.print "You must specify a file"

    currentArea = null
    currentSection = null
    stats =
      room: 0
      mob: 0
      area: 0
      item: 0

    printStatus = (status) ->
      mob.print "\x1b[1A\x1b[2K#{status}"
      log.debug status

    updateProgress = (task, total, action) ->
      printStatus "Area reset: [#{task}/#{total}] #{action}"

    resetArea = (area) ->
      area.on 'progress:reset', updateProgress
      area.reset()
      area.off 'progress:reset', updateProgress
      printStatus "Done importing area %c#{area.id}%."

    mob.print ''

    importer = imports.importer.getImporter fs.readFileSync args[0]
    if not importer?
      mob.print "Could not find importer for this file."

    importer.on 'area', (data) ->
      stats.area++
      if currentArea?
        log.info "Starting new area, resetting previous area."
        resetArea currentArea

      currentArea = world.areas.get data.id
      if currentArea?
        currentArea.set data
        printStatus "Reloading area %c#{currentArea.id}%."
        mob.print ''
        return

      currentArea = new model.models.area data
      world.areas.add currentArea
      printStatus "Creating area %c#{currentArea.id}%."
      mob.print ''

    importer.on 'room', (data) ->
      stats.room++
      vroom = currentArea.vrooms.get(data.id)
      if vroom?
        vroom.set data
        printStatus "Reloaded vRoom %c#{vroom.id}%. '%C#{vroom.get 'title'}%.'"
        return

      vroom = new model.models.room data
      printStatus "Adding vRoom %c#{vroom.id}%. '%C#{vroom.get 'title'}%.'"
      currentArea.vrooms.add vroom

    importer.on 'mobile', (data) ->
      stats.mob++
      vmob = currentArea.vmobs.get(data.id)
      if vmob?
        vmob.set data
        printStatus "Reloaded vMob %c#{vmob.id}%. '%C#{vmob.get 'name'}%.'"
        return

      vmob = new model.models.mob data
      printStatus "Adding vMob %c#{vmob.id}%. '%C#{vmob.get 'name'}%.'"
      currentArea.vmobs.add vmob

    importer.on 'item', (data) ->
      stats.item++
      vitem = currentArea.vitems.get(data.id)
      if vitem?
        vitem.set data
        printStatus "Reloaded vItem %c#{vitem.id}%. '%C#{vitem.get 'name'}%.'"
        return

      vitem = new model.models.item data
      printStatus "Adding vItem %c#{vitem.id}%. '%C#{vitem.get 'name'}%.'"
      currentArea.vitems.add vitem

    importer.on 'done', ->
      resetArea currentArea
      printStatus "Done importing #{stats.area} areas, #{stats.room} rooms,
        #{stats.mob} mobs, #{stats.item} items"

    importer.read callback
