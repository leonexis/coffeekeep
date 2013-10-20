{Model, Collection} = require './base'
{RoomCollection} = require './room'
{MobCollection} = require './mob'
{ItemCollection} = require './item'

exports.Area = class Area extends Model
    storedCollections: ['vrooms', 'vmobs', 'vitems'] #, 'rooms']

    initialize: ->
        # Each area handles all mobs, items, etc with accessors on the room
        # class object

        # Virtual Collections. These are saved as part of the core area and serve
        # as the templates for loaded rooms/mobs/items, etc.. during area reset.
        # Vrooms can contain mob and item instances and these will be
        # cloned when room instances are made.
        @vrooms = new RoomCollection @
        @vmobs = new MobCollection @ # Does not include users (see @world)
        @vitems = new ItemCollection @

        # Instance Collections. These should be saved regularly in case of
        # server crash, etc, but will be replaced during a reset. In this case
        # rooms takes care of its own mobs, items. Mobs take care of its own
        # inventory, equipment, but each point to vitual ID in the area
        @rooms = new RoomCollection @
        @rooms.urlPart = 'irooms'

        @on 'loadedCollections', (model) ->
            return unless model is @
            @reset()

    toString: ->
        return "[Area #{@id}]"

    # Reset the area
    reset: ->
        console.log "#{@}: Resetting area"
        tasks = 1 + @vrooms.length
        current = 0
        @emit 'progress:reset', ++current, tasks, "Clear rooms"
        @rooms.reset()
        @vrooms.forEach (vroom) =>
            #console.log "adding room instance from vroom #{vroom.id}"
            @emit 'progress:reset', ++current, tasks, "Adding room instance #{vroom.id}"
            room = vroom.cloneVirtual()
            @rooms.add room

        console.log "#{@}: Reset complete"

exports.AreaCollection = class AreaCollection extends Collection
    model: Area
    urlPart: 'areas'