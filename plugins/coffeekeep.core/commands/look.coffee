new Command
  name: 'look'
  aliases: ['l']
  description: "Describes the environment around the player."
  help: "Usage: look [direction or object]"
  action: (context, request) ->
    util = require 'util'
    {mob, room, area, world} = context
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
            if mob.hasCookie "look_extra_#{locId}_#{extra.keywords}"
              desc = desc.replace re, "$1%X$2%L$3"
            else
              desc = desc.replace re, "$1%x$2%L$3"
        mob.print "%L#{desc}%."
        exits = " exits: "
        history = mob.getCookie("mob_location_history") ? []
        for direction, link of room.get 'links'
          roomId = link.room
          if '#' not in roomId
            roomId = world.resolveLocationId roomId

          color = 'o'
          if link.door
            color = 'd'
          if roomId not in history
            color = color.toUpperCase()

          if not roomId
            color = 'R'

          exits += "%#{color}#{direction}%. "
        mob.print exits

        for othermob in room.getMobs()
          mob.print "  %m#{othermob.getDisplayText context}%."

      when 'self'
        # TODO: Write a better report when looing at self
        mob.write util.inspect mob.attributes
        mob.print ''

      else
        # extras
        extras = room.get('extras') or []
        for extra in extras
          continue if not extra.keywords?
          for keyword in extra.keywords.split ' '
            if noun is keyword.toLowerCase()
              mob.print extra.description
              mob.setCookie "look_extra_#{locId}_#{extra.keywords}"
              return

        # TODO: directions
        mob.print 'Sorry, you can only currently look at the room or yourself.
          Perhaps buy better glasses?'
