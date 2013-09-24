new Command
    name: 'look'
    aliases: ['l']
    description: "Describes the environment around the player."
    help: "Usage: look [direction or object]"
    action: (context, request) ->
        {mob, room} = context
        mob.print "%T#{room.get 'title'}%."
        mob.print "%L#{room.get 'description'}%."
        exits = " exits: "
        for direction, link of room.get 'links'
            exits += "%o#{direction}%. "
        mob.print exits