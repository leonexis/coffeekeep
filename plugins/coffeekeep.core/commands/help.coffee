new Command
  name: 'help'
  aliases: []
  description: "Provides help on any command."
  help: "Usage: help [command]"
  action: (context, request) ->
    {mob, room, world, area} = context
    {verb, args} = request
    noncanonical = 0

    if verb is 'help'
      if args.length < 1
        mob.print "\r\nWhat can I help you with today?\r\n"
        return

      verb = args[0].toLowerCase()
      canonicalverb = verb

    world.commands.forEach (command) ->
      aliases = command.get 'aliases'
      if aliases? and aliases.length > 0
        for currentalias in aliases
          if (verb == currentalias)
            verb = command
            noncanonical = 1


    command = world.commands.get verb

    if not command?
      mob.print "\r\nI don't know what that means, so I can't help you there.
        \r\n"
      return

    helpstring = command.get 'help'
    description = command.get 'description'

    if noncanonical
      parentcommand = command.get 'name'
      canonicalverb += " (alias for #{parentcommand})"

    if (description == "I don't really do anything")
      description = "A description has not yet been added."

    if (helpstring == "Usage: lazy. Dats it")
      helpstring = "Usage: A usage format has not yet been added."

    mob.print "\r\nHelp for #{canonicalverb}:\r\n\r\n
      Description: #{description}\r\n\r\n#{helpstring}\r\n"
