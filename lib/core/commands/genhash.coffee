new Command
    name: 'genhash'
    aliases: []
    description: "Generates hash values"
    help: "Usage: genhash [hash algorithm] [password]"
    action: (context, request) ->
        {mob, world} = context
        {verb, args} = request
        crypto = require 'crypto'
        
        currentver = 1
        
        if args.length < 2
            mob.print "\r\nPlease read the genhash help information before using.\r\n"
            return
        
        hashtype = args[0]
        password = args[1]
        salt = ""
        salt += Math.random().toString(36).substr(2) while salt.length < 8
        salt = salt.substr 0,8
        
        tohash = salt + password
        outtext = hashtype + ":" + currentver + ":" + salt + ":"
        
        try
            hashedpass = crypto.createHash(hashtype).update(tohash).digest('hex')
        catch error
            mob.print "\r\nInvalid hashing! #{error}\r\n"
            return
            
        outtext += hashedpass
        
        mob.print "\r\n#{outtext}\r\n"