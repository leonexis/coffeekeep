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
      return do callback

    printStatus = (status) =>
      mob.print "\x1b[1A\x1b[2K#{status}"
      @log.silly status

    updateProgress = (task, total, action) ->
      printStatus "Area save: [#{task}/#{total}] #{action}"

    switch args[0]
      when 'area'
        mob.print "Saving area..."
        area.save null,
          recursive: true
          success: ->
            mob.print "Area saved."
            do callback
          error: (err) ->
            mob.print "An error occured, see console."
            @log.error "Error during save:", err
            callback err
      when 'areas'
        mob.print "Saving all areas..."
        callbacks = world.areas.map (area) -> (cb) ->
          printStatus "Saving area #{area.id}"
          area.save null,
            recursive: true
            success: ->
              printStatus "Area #{area.id} saved."
              mob.print ''
              cb null
            error: (err) ->
              mob.print "An error occured saving area #{area.id}."
              @log.error "Error while saving %s:", area.id, err
              cb err
        async.parallel callbacks, (err) ->
          if (err)
            mob.print "An error occured while saving areas."
            @log.error "An error occured while saving areas.", err
            return
          callback null

      when 'world'
        mob.print "Saving world config..."
        world.save null,
          recursive: false
          success: ->
            mob.print "World config saved."
            do callback
          error: (err) ->
            mob.print "An error occured, see console."
            @log.error "Error during save:", err
            callback err
      else
        mob.print "Invalid resource."
        return do callback
