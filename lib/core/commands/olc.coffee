new Command
    name: 'olc'
    aliases: []
    description: "OnLine Creator"
    help: "Usage: olc room edit [title|description]"
    action: (context, request, callback) ->
        {mob, room, session} = context
        {verb, args} = request
        if not session?
            mob.print "This command must be used within a terminal session."
            return do callback

        if args[0] isnt 'room' or args[1] isnt 'edit'
            mob.print "Must start with 'olc room edit'"
            return do callback

        attr = args[2]
        if attr not in ['title', 'description']
            mob.print "Can't change that"
            return do callback

        session.question "New text: ", (response) ->
            room.set attr, response
            return do callback

