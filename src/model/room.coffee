{Model, Collection} = require './'

exports.Room = class Room extends Model

exports.RoomCollection = class RoomCollection extends Collection
    model: Room
