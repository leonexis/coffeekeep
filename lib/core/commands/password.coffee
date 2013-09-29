new Command
    name: 'password'
    aliases: ['pword']
    description: "Changes the password on the current account."
    help: "Usage: password [old password] [new password]"
    action: (context, request) ->
        {mob, room, world, area} = context
        {verb, args} = request
        
        currentlogin = mob.id
        
        if args.length < 2
            mob.print "\r\nYou must enter the old password and the new password (see help for details).\r\n"
            return
        
        oldpass = args[0]
        newpass = args[1]
        
        usertoedit = world.users.get currentlogin
        
        if not (usertoedit.checkPassword oldpass)
            mob.print "\r\nThe old password was not correct. Please check it and try again.\r\n"
            return
            
        usertoedit.setPassword newpass
        mob.print "\r\nPassword successfully changed!\r\n"
        mob.save
        