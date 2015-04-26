{Model, Collection} = require './base'
{MobCollection} = require './mob'
{ItemCollection} = require './item'

class Room extends Model
  savedCollections: ['mobs', 'items']

  defaults: ->
    links: []
    extras: []

  initialize: ->
    # TODO: convert exits, specials, etc to collections
    @mobs = new MobCollection @
    @items = new ItemCollection @

  getArea: ->
    @collection?.parent

  getLocationId: ->
    "#{@getArea()?.id}##{@id}"

  toString: ->
    "[Room #{@getLocationId()}]"

  getMobs: ->
    mobs = []
    here = @getLocationId()
    mobs = @world.users.filter (mob) ->
      mob.get('currentLocation') is here

  # For standard rooms, instance id is the same as virtual. Non-standard
  # rooms (mazes) may wish to do something differently
  cloneVirtual: (newId) ->
    newId ?= @id
    super newId

class RoomCollection extends Collection
  model: Room
  urlPart: 'rooms'

exports.Room = Room
exports.RoomCollection = RoomCollection
