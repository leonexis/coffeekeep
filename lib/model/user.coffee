{Mob, MobCollection} = require './mob'

exports.User = class User extends Mob
    defaults:
        age: 0                      # Player age in days
        wasAtLocation: null         # Player location before last disconnect
        passwordHash: null          # Salted and encrypted password hash
    
    idAttribute: 'name'
    
    setPassword: (password) ->
        # TODO: store password as salted hash
        @set 'password', "cleartext:#{password}"
    
    checkPassword: (password) ->
        # TODO: check password agaisnt salted hash
        realpass = @get 'password'
        "cleartext:#{password}" == realpass

exports.UserCollection = class UserCollection extends MobCollection
    model: User
