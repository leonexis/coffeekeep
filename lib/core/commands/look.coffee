new Command
    name: 'look'
    aliases: ['l']
    description: "Describes the environment around the player."
    help: "Usage: look [direction or object]"
    action: (context, request) ->
        util = require 'util'
        {mob, room} = context
        {verb, args} = request
        
        noun = args[0] ? 'room'
        
        switch noun
            when 'room'
                mob.print "%T#{room.get 'title'}%."
                mob.print "%L#{room.get 'description'}%."
                exits = " exits: "
                for direction, link of room.get 'links'
                    exits += "%o#{direction}%. "
                mob.print exits
                
                for othermob in room.getMobs()
                    mob.print "    %m#{othermob.getDisplayText context}%."
            
            when 'self'
                console.log JSON.stringify util
                mob.write util.inspect mob.attributes
                mob.print ''