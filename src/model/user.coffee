{Mob, MobCollection} = require './mob'

exports.User = class User extends Mob
    defaults:
        #id: username
        password: null
    
    setPassword: (password) ->
        # TODO: store password as salted hash
        @set 'password', "cleartext:#{password}"
    
    checkPassword: (password) ->
        # TODO: check password agaisnt salted hash
        realpass = @get 'password'
        "cleartext:#{password}" == realpass

exports.UserCollection = class UserCollection extends MobCollection
    model: User
