new Command
  name: 'channels'
  description: "Lists all channels and subscription status"
  help: "Usage: channels"
  consumes: ['messaging']
  action: (context, request) ->
    {mob} = context
    {messaging} = imports

    mob.print "Channels available to you:"

    messaging.channels.map (channel) ->
      return unless mob.hasPermission channel.get 'acl'
      if channel.isEnabled context
        enabled = "%genabled%."
      else
        enabled = "%rdisabled%."

      perms = ''
      if mob.hasPermission '-all +sysop'
        perms = " %K(ACL: #{channel.get 'acl'})%."
      mob.print "  %c#{channel.id}%.: #{enabled}#{perms}"
