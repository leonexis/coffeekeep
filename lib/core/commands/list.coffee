new Command
    name: 'list'
    aliases: ['commands', 'users']
    description: "Lists the specified resource"
    help: "Usage: list [areas|rooms|commands|users]"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if verb is 'list'
            if args.length < 1
                mob.print "Which resource?"
                return

            verb = args[0].toLowerCase()

        switch verb
            when 'areas'
                world.areas.forEach (area) ->
                    mob.print "%c#{area.id}%. - %T#{area.get 'title'}%."
            when 'rooms'
                area.rooms.forEach (room) ->
                    mob.print "%c#{room.id}%. - %T#{room.get 'title'}%."
            when 'commands'
                world.commands.forEach (command) ->
                    mob.print "%c#{command.id}%. - %T#{command.get 'description'}%."
                    aliases = command.get 'aliases'
                    if aliases? and aliases.length > 0
                        mob.print "  aliases: #{aliases}"
            when 'users'
                world.users.forEach (user) ->
                    mob.print "%c#{user.id}%. - %T#{user.get 'shortDescription'}%."