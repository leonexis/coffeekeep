new Command
    name: 'help'
    aliases: []
    description: "Provides help on any command."
    help: "Usage: help [command]"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if verb is 'help'
            if args.length < 1
                mob.print "What can I help you with today?"
                return
                
            verb = args[0].toLowerCase()
        
        
        command = world.commands.get verb
        
        if not command?
            mob.print "I don't know what that means, so I can't help you there."
            return
        
        helpstring = command.get 'help'
        description = command.get 'description'
        
        if (description == "I don't really do anything")
            description = "A description has not yet been added."
            
        if (helpstring == "Usage: lazy. Dats it")
            helpstring = "Usage: A usage format has not yet been added."
        
        mob.print "\r\nHelp for #{verb}:\r\n\r\nDescription: #{description}\r\n\r\n#{helpstring}"