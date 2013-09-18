{Model, Collection} = require './'

exports.Mob = class Mob extends Model
    defaults:
        title: 'Untitled mob'
        location: null
    
    moveTo: (room) ->
        last = @get 'location'
        if last?
            [areaid, roomid] = last
            lastarea = world.areas.get areaid
            if room.area is not lastarea
                lastarea.mobs.remove @
                room.area.mobs.add @
        else
            room.area.mobs.add @

exports.MobCollection = class MobCollection extends Collection
    model: Mob