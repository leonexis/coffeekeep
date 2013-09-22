{Model, Collection} = require './'
{AreaCollection} = require './area'
{CommandCollection} = require './command'
{UserCollection} = require './user'

exports.World = class World extends Model
    initialize: ->
        @areas = new AreaCollection @
        @commands = new CommandCollection @
        @users = new UserCollection @
        @world = @
    
    getStartRoom: ->
        area = @world.areas.first()
        if not area?
            throw new Error "Could not find any areas in the world"
        room = area.rooms.first()
        if not room?
            throw new Error "Could not find any rooms in #{area.toString()}"
        room