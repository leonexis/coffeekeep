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
        noun = noun.toLowerCase()
        locId = room.getLocationId()

        switch noun
            when 'room'
                mob.print "%T#{room.get 'title'}%."
                desc = room.get 'description'
                extras = room.get('extras') or []
                for extra in extras
                    continue if not extra.keywords?
                    for keyword in extra.keywords.split ' '
                        re = new RegExp "(^|\\W)(#{keyword})(\\W|$)", "i"
                        if mob.hasTattoo "look:extra:#{locId}:#{extra.keywords}"
                            desc = desc.replace re, "$1%X$2%L$3"
                        else
                            desc = desc.replace re, "$1%x$2%L$3"
                mob.print "%L#{desc}%."
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

            else
                # extras
                extras = room.get('extras') or []
                for extra in extras
                    continue if not extra.keywords?
                    for keyword in extra.keywords.split ' '
                        if noun is keyword
                            mob.print extra.description
                            mob.setTattoo "look:extra:#{locId}:#{extra.keywords}"
                            return

                # TODO: directions

                mob.print 'Sorry, you can only currently look at the room or yourself. Perhaps buy better glasses?'