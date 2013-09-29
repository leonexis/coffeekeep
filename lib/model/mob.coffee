_ = require 'underscore'
{Model, Collection} = require './'
{format} = require '../format'

exports.Mob = class Mob extends Model
    @gender:    # Appearance/portraial
        genderless: 0   # No gender traits possbible 
        male: 1         # Treated like biological male, even if not open trans
        female: 2       # Treated like biological female, even if non open trans
        transman: 3     # Openly transgender man. Uses male pronouns, but profile shows transman
        transwoman: 4   # Openly transgender woman. Uses female pronouns, but profile shows transwoman
        androgynous: 5  # Wishes to portray no gender. Uses alternate pronouns: zhe/zher(s)
    
    @sex:       # Sexual mechanic
        none: 0         # No sexual mechanic
        male: 1         # Male sexual mechanic
        female: 2       # Female sexual mechanic
        intersex: 3     # Both male and female mechanics
        
    defaults:
        name: 'unnamed'
        shortDescription: 'an unnamed mob'
        longDescription: 'A generic formless mob. So much, in fact, that
 looking at {him} hurts the eyes.'
        extraDescription: 'This would be a long extra description... if it were
 written, of course.'
        gender: @gender.genderless      # Determines he/she/it/zhe
        sex: @sex.none                  # Determines sexual mechanics
        height: 150                     # Height in cm
        weight: 80                      # Weight in kg
        
        currentLocation: null
    
    initialize: ->
        @sessions = []
    
    toString: -> "[mob #{@id}]"
    
    addSession: (session) ->
        # Add an open session
        @sessions.push session
    
    removeSession: (session) ->
        @sessions = _.without @sessions, session
    
    write: (data) -> session.write data for session in @sessions
    
    print: (objs...) -> 
        @write format obj.toString() + ' ' for obj in objs
        @write '\r\n'
    
    getLocation: ->
        # Get a reference to the room that the mob is in
        loc = @get 'currentLocation'
        if not loc?
            loc = @world.getStartRoom().getLocationId()
            @set 'currentLocation', loc
            
        [areaId, roomId] = loc.split '#'
        area = @world.areas.get areaId
        if not area?
            console.error "ERROR: the area where #{@id}:#{@get 'title'} was
 located no longer exists! Putting him in the first room of the first area."
            room = @world.getStartRoom()
            @set 'currentLocation', room.getLocationId()
        else
            room = area.rooms.get roomId
        
        return room
    
    setLocation: (room) ->
        # TODO Add/remove quick lookups to area/room
        @set 'currentLocation', room.getLocationId()
    
    doCommand: (commandStr, callback) ->
        callback ?= ->
        room = @getLocation()
        context = 
            mob: @
            room: room
            world: @world
            area: do room.getArea
            
        @world.commands.doCommand context, commandStr, callback

exports.MobCollection = class MobCollection extends Collection
    model: Mob
    urlPart: 'mobs'
    