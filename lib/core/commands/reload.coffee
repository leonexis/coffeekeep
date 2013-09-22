new Command
    name: 'reload'
    aliases: []
    description: "Reloads specified resource"
    help: "Usage: reload commands"
    action: (context, request) ->
        {mob, world} = context
        {verb, args} = request
        if args.length < 1
            mob.print "What do you want to reload?"
            return
        
        switch args[0].toLowerCase()
            when 'commands'
                world.commands.forEach (command) ->
                    console.log "Reloading command #{command.id}"
                    world.commands.loadFile command.get('fileName'), true
                    mob.print "Reloaded command #{command.id}."
            else
                mob.print "Not a valid resource: #{args[0]}"