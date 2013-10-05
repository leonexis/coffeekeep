_ = require 'underscore'

new Command
    name: 'config'
    description: "Configure the specified resource"
    help: "Usage: config [self|world|area] [list|get|set|delete] <key> <data>"
    action: (context, request, callback) ->
        {mob, room, world, area} = context
        {verb, args} = request

        if args[0] in ['get', 'set', 'list', 'unset']
            target = 'self'
            [action, key, data] = args
        else
            [target, action, key, data] = args

        targetObj = switch target
            when 'self' then mob
            when 'world' then world
            when 'area' then area
        
        if not targetObj?
                mob.print "Invalid target"
                return callback null, false

        switch action
            when 'get'
                data = targetObj.get key
                mob.print "#{target} #{key} is #{JSON.stringify data}."
                return callback null, true
            when 'set'
                targetObj.set key, data
                mob.print "#{target} #{key} set to #{JSON.stringify data}."
                return callback null, true
            when 'unset'
                targetObj.unset key
                mob.print "#{target} #{key} unset."
            when 'list'
                mob.print "#{target} list:"
                seen = []
                defaults = targetObj.defaults
                attrs = targetObj.attributes
                if _.isObject defaults
                    for k, v of defaults
                        if attrs[k]? and attrs[k] isnt v
                            mob.print " %c#{k}%.: #{JSON.stringify attrs[k]} %K(default: #{JSON.stringify v})%."
                        else
                            mob.print " %c#{k}%.: %K#{JSON.stringify v} (default)%."
                        seen.push k

                for k, v of attrs
                    continue if k in seen
                    mob.print " %c#{k}%.: #{JSON.stringify v}"

                return callback null, true

            else
                mob.print "Invalid action."
                return callback null, false

        return callback null, true