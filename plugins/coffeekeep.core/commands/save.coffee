async = require 'async'
new Command
  name: 'save'
  acl: '-all +sysop'
  description: "Lists the specified resource"
  help: "Usage: save [area]"
  action: (context, request, callback) ->
    {mob, room, world, area} = context
    {verb, args} = request
    if args.length < 1
      mob.print "Which resource?"
      return process.nextTick callback

    printStatus = (status) ->
      mob.print "\x1b[1A\x1b[2K#{status}"
      log.silly status

    updateProgress = (task, total, action) ->
      printStatus "Area save: [#{task}/#{total}] #{action}"

    saveArea = (area, cb) ->
      printStatus "Saving area #{area.id}"
      area.save recursive: true, (err) ->
        if err?
          mob.print "An error occured, see console."
          log.error "Error during save:", err, err.stack
          return cb err
        printStatus "Area #{area.id} saved."
        mob.print ''
        cb null

    switch args[0]
      when 'area'
        mob.print ''
        saveArea area, callback

      when 'areas'
        tasks = world.areas.map (area) -> (cb) -> saveArea area, cb

        mob.print "Saving all areas..."
        mob.print ''
        async.series tasks, (err) ->
          if (err)
            mob.print "An error occured while saving areas."
            log.error "An error occured while saving areas.", err, err.stack
            return callback err
          callback null

      when 'world'
        mob.print "Saving world config..."
        world.save recursive:false, (err) ->
          if err?
            mob.print "An error occured, see console."
            log.error "Error during save:", err
            return callback err

          mob.print "World config saved."
          callback null

      else
        mob.print "Invalid resource."
        return process.nextTick callback
