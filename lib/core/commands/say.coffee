new Command
    name: 'say'
    aliases: ['yell', 'growl']
    description: "Says (or yells, or growls) something to every mob in the room."
    help: "Usage: say (or yell, or growl) [message]"
    action: (context, request) ->
        util = require 'util'
        {mob, room} = context
        {verb, args} = request
        
        message = args.join(" ")
        speaker = mob.get 'name'
        
        switch verb
            when 'yell'
                message = message.toUpperCase()
                verb += "s, '"
            when 'growl'
                message = message.toLowerCase()
                verb += "s, '"
            else
                verb += "s, '"
                
        for othermob in room.getMobs()
            othermob.print "%g#{speaker} #{verb}#{message}'%."