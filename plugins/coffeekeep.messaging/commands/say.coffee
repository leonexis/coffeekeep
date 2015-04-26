new Command
  name: 'say'
  aliases: ['yell', 'growl']
  description: "Says (or yells, or growls) something to every mob in the room."
  help: "Usage: say (or yell, or growl) [message]"
  consumes: ['messaging']
  action: (context, request) ->
    util = require 'util'
    {mob, room} = context
    {verb, args} = request
    {messaging} = imports

    message = args.join(" ")
    speaker = mob.get 'name'

    switch verb
      when 'yell'
        message = message.toUpperCase()
      when 'growl'
        message = message.toLowerCase()

    msg = new messaging.Message
      subject: mob
      message: "%g{Name} #{verb}{s} '{content}'%."
      content: message

    for othermob in room.getMobs()
      othermob.print msg.forObserver othermob
