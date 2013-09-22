new Command
    name: 'goto'
    description: "Teleports the player to the specified location"
    help: "Usage: goto <room id>"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        if args.length < 1
            mob.print "You must specify a room id."
        
        roomId = args[0]
        if '#' in roomId
            [areaId, roomId] = roomId.split '#'
            newArea = world.areas.get 'areaId'
            if not newArea?
                mob.print "That area is not loaded or does not exist."
                return
            newRoom = newArea.get roomId
            if not newRoom?
                mob.print "That room doesn't exist in that area."
                return
        else
            newRoom = area.rooms.get roomId
            if not newRoom?
                mob.print "That room doesn't exist."
                return
        
        mob.setLocation newRoom
        mob.doCommand 'look'
        
