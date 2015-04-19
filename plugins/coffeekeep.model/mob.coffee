_ = require 'underscore'
util = require 'util'
{Model, Collection} = require './base'
{format} = require '../coffeekeep.core/format'
security = require '../coffeekeep.core/security'

class Mob extends Model
    @gender:            # Appearance/portraial
                        # NOTE: these numbers are used for formatting
        genderless: 0   # No gender traits possbible
        male: 1         # Treated like biological male, even if not open trans
        female: 2       # Treated like biological female, even if non open trans
        androgynous: 3  # Wishes to portray no gender. Uses alternate pronouns: zhe/zher(s)
        # Can have alternate gender that uses genderless pronouns as #4
        transman: 5     # Openly transgender man. Uses male pronouns, but profile shows transman
        transwoman: 6   # Openly transgender woman. Uses female pronouns, but profile shows transwoman
        # Can have alternate gender that uses androgynous as #7

    @sex:               # Sexual mechanic
        none: 0         # No sexual mechanic
        male: 1         # Male sexual mechanic
        female: 2       # Female sexual mechanic
        intersex: 3     # Both male and female mechanics

    @maxLocationHistory: 50 # Maximum number of rooms to keep in history cookie

    defaults: ->
        name: 'unnamed'
        shortDescription: 'an unnamed mob'
        longDescription: 'A generic formless mob. So much, in fact, that
 looking at {him} hurts the eyes.'
        extraDescription: 'This would be a long extra description... if it were
 written, of course.'
        gender: Mob.gender.genderless      # Determines he/she/it/zhe
        sex: Mob.sex.none                  # Determines sexual mechanics
        height: 150                     # Height in cm
        weight: 80                      # Weight in kg
        tattoos: {}                     # Invisible IDs assigned by other commands

        currentLocation: null
        channels: {}                    # List of channels and subscription status

    initialize: ->
        @sessions = []
        @cookies = {}
        @resolver = new MobAttributeResolver @

        # Keep track of the last fiew locations
        @on 'change:currentLocation', (model, value, options) =>
            return if model isnt @
            history = @getCookie("mob_location_history") ? []
            history.push value
            while history.length > Mob.maxLocationHistory
                history.shift()
            @setCookie "mob_location_history", history
        

    hasPermission: (acl, permission) -> @resolver.hasPermission acl, permission
    mustHavePermission: (acl, permission) ->
        if not @hasPermission acl, permission
            throw new security.InsufficientPermissionsError
                mob: @
                permission: permission ? ''
                mask: acl

    toString: -> "[mob #{@id}]"

    getDisplayText: (context) ->
        if context?.mob? and context.mob is @
            return "You stand here."

        title = @get 'shortDescription'
        title ?= @get 'name'
        title ?= 'someone'
        title = title[0].toUpperCase() + title[1..]
        title += ' stands here.'
        title

    addSession: (session) ->
        # Add an open session
        @sessions.push session

    removeSession: (session) ->
        @sessions = _.without @sessions, session

    write: (data) -> session.write data for session in @sessions

    print: (objs...) ->
        for session in @sessions
            session.print format obj.toString() + ' ' for obj in objs

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

    doCommand: (context, commandStr, callback) ->
        # Possible signatures:
        # (commandStr<String>)
        # (commandStr<String>, callback<Function>)
        # (context<Object>, commandStr<String>)
        # (context<Object>, commandStr<String>, callback<Function>)
        if _.isString context
            callback = commandStr
            commandStr = context
            context = {}

        callback ?= ->
        context = @getContext context

        @world.interpreter.doCommand context, commandStr, callback

    getContext: (context) ->
        room = @getLocation()
        _.defaults context,
            mob: @
            room: room
            world: @world
            area: room.getArea()

    readlineCompleter: (context, line, callback) ->
        context = @getContext context
        @world.interpreter.readlineCompleter context, line, callback

    ###
    Find unique and prefered target names based on the filter.
    Collections could be:

     - `mobs` - mobs in the current room
     - `users` - users in game

    TODO:

     - `exits` - exits in the room
     - `specials` - specials in the room (signs, etc)
     - `items` - items in the room
     - `inventory` - items in mob's inventory
    ###
    getTargets: (context, collections, filter) ->
        context = @getContext context
        collections ?= ['mobs']
        if not _.isArray collections
            collections = [collections]
        models = []
        for collection in collections
            switch collection
                when 'mobs'
                    models = models.concat context.room.getMobs()
                when 'users'
                    models = models.concat context.world.users.models

        targets = {}
        seen = {}
        for model in models
            name = model.get 'name'
            if not seen[model.name]?
                seen[name] = 0
                targets[name] = model
            else
                seen[name] += 1
                targets["#{name}.#{seen[name]}"] = model

        targets

    # Perminant saved tracking information (achievements, crimes, etc)
    hasTattoo: (tattoo) ->
        tattoos = @get 'tattoos'
        tattoos ?= {}
        tattoos[tattoo] != undefined

    getTattoo: (tattoo) ->
        tattoos = @get 'tattoos'
        tattoos ?= {}
        tattoos[tattoo]

    setTattoo: (tattoo, value=true) ->
        tattoos = @get 'tattoos'
        tattoos ?= {}
        tattoos[tattoo] = value
        @set 'tattoos', tattoos

    unsetTattoo: (tattoo) ->
        tattoos = @get 'tattoos'
        tattoos ?= {}
        if tattoos[tattoo] != undefined
            delete tattoos[tattoo]
        @set 'tattoos', tattoos

    # Temporary tracking information (seen rooms, room extras, etc)
    hasCookie: (cookie) -> @cookies[cookie] != undefined
    getCookie: (cookie) -> @cookies[cookie]
    setCookie: (cookie, value=true) -> @cookies[cookie] = value
    unsetCookie: (cookie) -> delete @cookies[cookie] if @hasCookie cookie



class MobCollection extends Collection
    model: Mob
    urlPart: 'mobs'

class MobAttributeResolver extends security.AttributeResolver
    constructor: (@mob) ->
    get: (k) -> @mob.get k
    equal: (k, v) ->
        switch k
            when 'gender'
                return super k, v if not _(Mob.gender).has v
                n = Mob.gender[v]
                # Return true if direct match
                return true if n is @get k
                # Return true if mob's base gender matches
                return true if n < 4 and n is @get(k) % 4
                return false
            else
                return super k, v

exports.Mob = Mob
exports.MobCollection = MobCollection
exports.MobAttributeResolver = MobAttributeResolver
