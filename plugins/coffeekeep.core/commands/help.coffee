_ = require 'lodash'

new Command
  name: 'help'
  aliases: []
  description: "Provides help on any command."
  help: "Usage: help [command]"
  consumes: ['interpreter']
  action: (context, request) ->
    {mob, room, world, area} = context
    {verb, args} = request
    {interpreter} = imports
    noncanonical = 0

    if verb is 'help'
      if args.length < 1
        mob.print "\r\nWhat can I help you with today?\r\n"
        return

      verb = args[0].toLowerCase()
      canonicalverb = verb

    command = interpreter.getVerb verb

    # Make sure mob has permission to run the command
    if command.acl? and not mob.hasPermission command.acl
      command = null

    if not command?
      mob.print "\r\nI don't know what that means, so I can't help you there.
        \r\n"
      return

    if command.verb isnt verb
      noncanonical = 1

    helpstring = command.help
    description = command.description

    if noncanonical
      parentcommand = command.verb
      canonicalverb += " (alias for #{parentcommand})"

    if not description? or description is "I don't really do anything"
      description = "A description has not yet been added."

    if not helpstring? or helpstring is "Usage: lazy. Dats it"
      helpstring = "Usage: A usage format has not yet been added."

    mob.print "Help for #{canonicalverb}:"
    mob.print ''
    mob.print "  Description: #{description}"
    mob.print ''
    mob.print helpstring

    if mob.hasPermission '-all +sysop'
      mob.print ''
      mob.print "Extended Information:"
      for key in _.keys command
        continue if key in ['provider', 'help', 'description']
        mob.print "  #{key}: #{JSON.stringify command[key]}"
