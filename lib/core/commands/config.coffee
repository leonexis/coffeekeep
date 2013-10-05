new Command
    name: 'config'
    description: "Configure the specified resource"
    help: "Usage: config [self|world|area] [get|set] <key> <data>"
    action: (context, request, callback) ->
        {mob, room, world, area} = context
        {verb, args} = request

        if args[0] in ['get', 'set']
            target = 'self'
            [action, key, data] = args
        else
            [target, action, key, data] = args

        if action not in ['get', 'set']
            mob.print "Invalid action"
            return callback null, false

        switch target
            when 'self'
                if action is 'set'
                    mob.set key, data
                    mob.print "#{target} #{key} set to #{JSON.stringify data}"
                else
                    mob.print JSON.stringify mob.get key
            when 'world'
                if action is 'set'
                    world.set key, data
                    mob.print "#{target} #{key} set to #{JSON.stringify data}"
                else
                    mob.print JSON.stringify world.get key
            when 'area'
                if action is 'set'
                    action.set key, data
                    mob.print "#{target} #{key} set to #{JSON.stringify data}"
                else
                    mob.print JSON.stringify world.get key
            else
                mob.print "Unkown target"
                return callback null, false

        return callback null, true