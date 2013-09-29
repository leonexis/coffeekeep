new Command
    name: 'save'
    description: "Lists the specified resource"
    help: "Usage: save [area]"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if args.length < 1
            mob.print "Which resource?"
            return
                
        switch args[0]
            when 'area'
                mob.print "Saving area..."
                area.save null,
                    recursive: true
                    success: ->
                        mob.print "Area saved."
                    error: (err) ->
                        mob.print "An error occured, see console."
                        console.log "Error during save: #{err}"
