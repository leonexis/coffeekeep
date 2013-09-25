{Mob, MobCollection} = require './mob'

exports.User = class User extends Mob
    defaults:
        age: 0                      # Player age in days
        wasAtLocation: null         # Player location before last disconnect
        passwordHash: null          # Salted and encrypted password hash
    
    idAttribute: 'name'
    
    setPassword: (password) ->
        crypto = require 'crypto'
        
        # Set hashalgo to preferred hash algorithm. Algorithm names are the same as output by "openssl list-message-digest-algorithms"
        # When in doubt, the default "whirlpool" algorithm is a good choice. If whirlpool is not supported, use "sha512"
        hashalgo = 'whirlpool'
        
        # Setting insecurePlaintext to 1 will result in passwords being stored in plaintext.
        # This is VERY insecure and should not be enabled unless openssl support cannot be added.
        insecurePlaintext = 0
        
        if (insecurePlaintext)
            @set 'password', "cleartext:#{password}"
            console.log("ALERT: Using insecure cleartext password. Consider enabling hash storage.")
        else
            passtohash = password
            salt = ""
            salt += Math.random().toString(36).substr(2) while salt.length < 8
            salt = salt.substr 0,8
            passtohash = salt + passtohash
        
            hashedpass = crypto.createHash(hashalgo).update(passtohash).digest('hex')
            hashedoutput = hashalgo + ":1:" + salt + ":" + hashedpass
            @set 'password', "#{hashedoutput}"
    
    checkPassword: (password) ->
        crypto = require 'crypto'
        realpass = @get 'password'

        passsegments = realpass.split ':'
        hashtype = passsegments[0]
        if (hashtype == "cleartext")
            # Using insecure cleartext password storage
            "cleartext:#{password}" == realpass
        else
            hashsalt = passsegments[2]
            hashcheck = passsegments[3]
            tohash = hashsalt + password
            hashoutput = crypto.createHash(hashtype).update(tohash).digest('hex')
            hashoutput == hashcheck

exports.UserCollection = class UserCollection extends MobCollection
    model: User
