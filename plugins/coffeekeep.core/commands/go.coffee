new Command
    name: 'go'
    aliases: [
        'north', 'east', 'south', 'west', 'up', 'down', 'northwest',
        'northeast', 'southeast', 'southwest', 'n', 'e', 's', 'w', 'u', 'd',
        'nw', 'ne', 'se', 'sw', 'in', 'out', 'vortex', 'enter', 'leave']
    description: "Moves in the specified direction"
    help: "Usage: [go] <direction>"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if verb is 'go'
            if args.length < 1
                mob.print "Go where?"
                return

            verb = args[0].toLowerCase()

        direction = switch verb
            when 'north', 'n' then 'north'
            when 'east', 'e' then 'east'
            when 'south', 's' then 'south'
            when 'west', 'w' then 'west'
            when 'up', 'u' then 'up'
            when 'down', 'd' then 'down'
            when 'northwest', 'nw' then 'northwest'
            when 'northeast', 'ne' then 'northeast'
            when 'southeast', 'se' then 'southeast'
            when 'southwest', 'sw' then 'southwest'
            when 'enter', 'in' then 'enter'
            when 'leave', 'out' then 'leave'
            when 'vortex' then 'vortex'
            else null

        if not direction?
            mob.print "That isn't a valid direction."
            return

        link = room.get('links')[direction]
        if not link?
            mob.print "You can't go that way."
            return

        newRoom = world.getLocationById link.room, area
        if not newRoom?
            @log.error "Link to room does not exist.
                #{room.getLocationId()}->#{direction}: #{link.room}"
            mob.print "A dark energy prevents you from going that way."
            return

        mob.setLocation newRoom
        mob.doCommand 'look'
