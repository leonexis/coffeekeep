new Command
    name: 'save'
    description: "Lists the specified resource"
    help: "Usage: save [area]"
    action: (context, request, callback) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if args.length < 1
            mob.print "Which resource?"
            return do callback
                
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
                        console.log "Error during save: #{err}"
                        callback err
            else
                mob.print "Invalid resource."
                return do callback