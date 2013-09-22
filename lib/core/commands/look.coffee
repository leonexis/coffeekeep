exports.command =
    name: 'look'
    aliases: ['l']
    description: "Describes the environment around the player."
    help: "Usage: look [direction or object]"
    action: (context, request) ->
        {mob, room} = context
        mob.print "#{room.get 'title'}"
        mob.print "#{room.get 'description'}"
        mob.write " exits: "
        for direction, link of room.get 'links'
            mob.write "#{direction} "
        mob.print ''