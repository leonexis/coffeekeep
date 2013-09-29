new Command
    name: 'save'
    description: "Lists the specified resource"
    help: "Usage: save [area]"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if verb is 'list'
            if args.length < 1
                mob.print "Which resource?"
                return
                
            verb = args[0].toLowerCase()
        
        switch verb
            when 'area'
                area.save
                    success: ->
                        mob.print "Area saved."
