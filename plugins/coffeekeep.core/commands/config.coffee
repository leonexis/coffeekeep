_ = require 'underscore'
util = require 'util'

new Command
  name: 'config'
  acl: '-all +sysop'
  description: "Configure the specified resource"
  help: "Usage: config [self|world|area] [list|get|set|delete] <key> <data>"
  completer: (context, request) ->
    {verb, args} = request
    log.debug "config completer: %j", request
    hits = []
    targets = context.mob.getTargets context
    log.debug "targets: %j", targets
    if args.length is 1
      for target, model of targets
        continue if args[0] isnt '' and target.indexOf(args[0]) isnt 0
        hits.push "#{verb} #{target}"
      return [hits, "#{verb} #{args[0]}"]

    return [[],'']

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
      when 'room' then room
      when 'vroom' then room.virtual
      else mob.getTargets(context)[target]

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
        title = "#{target} list: "
        if targetObj.virtual?
          title += "%g(instance of virtual #{targetObj.virtual.toString()})%."
        mob.print title
        seen = []
        defaults = _.result targetObj, 'defaults'
        attrs = targetObj.attributes
        for k, v of defaults
          if attrs[k]? and attrs[k] isnt v
            mob.print " %c#{k}%.: #{JSON.stringify attrs[k]} %K(default:
              #{JSON.stringify v})%."
          else
            mob.print " %c#{k}%.: %K#{JSON.stringify v} (default)%."
          seen.push k

        if targetObj.virtual?
          for k, v of targetObj.virtual.attributes
            continue if k in seen
            seen.push k
            if attrs[k]? and attrs[k] isnt v
              mob.print " %c#{k}%.: #{JSON.stringify attrs[k]} %y(virtual:
                #{JSON.stringify v})%."
            else
              mob.print " %c#{k}%.: #{JSON.stringify v} %g(virtual)%."

        for k, v of attrs
          continue if k in seen
          mob.print " %c#{k}%.: #{JSON.stringify v}"

        return callback null, true

      else
        mob.print "Invalid action."
        return callback null, false

    return callback null, true
