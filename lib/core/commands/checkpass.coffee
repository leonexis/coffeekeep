new Command
    name: 'checkpass'
    aliases: []
    description: "Checks passwords"
    help: "Usage: checkpass [genhash output] [password to compare]"
    action: (context, request) ->
        {mob, world} = context
        {verb, args} = request
        crypto = require 'crypto'

        if args.length < 2
            mob.print "\r\nPlease read the checkpass help information before using.\r\n"
            return

        hashstring = args[0]
        password = args[1]
        hashparts = hashstring.split ":"

        hashtype = hashparts[0]
        version = hashparts[1]
        salt = hashparts[2]
        hash = hashparts[3]

        tohash = salt + password

        try
            outhash = crypto.createHash(hashtype).update(tohash).digest('hex')
        catch error
            mob.print "\r\nInvalid hashing! #{error}\r\n"
            return

        if (outhash == hash)
            mob.print "\r\nSuccess!\r\n"
        else
            mob.print "\r\nFailure!\r\n"