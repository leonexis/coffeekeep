util = require 'util'
{Model, Collection} = require './'
{AreaCollection} = require './area'
{CommandCollection} = require './command'
{UserCollection} = require './user'

exports.World = class World extends Model
    url: '/world'
    
    initialize: ->
        @areas = new AreaCollection @
        @commands = new CommandCollection @
        @users = new UserCollection @
        @world = @
    
    startup: (cb) ->
        @commands.loadDirectory __dirname + '/../core/commands'
        @users.fetch
            success: =>
                console.log "Fetched users: #{util.inspect @users}"
                do cb
        
    
    getStartRoom: ->
        area = @world.areas.first()
        if not area?
            throw new Error "Could not find any areas in the world"
        room = area.rooms.first()
        if not room?
            throw new Error "Could not find any rooms in #{area.toString()}"
        room