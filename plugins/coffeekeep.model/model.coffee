{Area, AreaCollection} = require './area'
{Model, Collection} = require './base'
{Item, ItemCollection} = require './item'
{Mob, MobCollection} = require './mob'
{Room, RoomCollection} = require './room'
{User, UserCollection} = require './user'
{World, WorldCollection} = require './world'
debug = require('debug') 'coffeekeep.model:register'

class ModelPlugin
  constructor: (@options, @imports) ->
    @models =
      base: Model

    @collections =
      base: Collection

  register: (name, model, collection) ->
    @models[name] = model
    @collections[name] = collection

module.exports = (options, imports, register) ->
  {log, storage} = imports

  Model::sync = Collection::sync = storage.sync
  Model::Logger = Collection::Logger = log.Logger

  model = new ModelPlugin options, imports
  model.register 'area', Area, AreaCollection
  model.register 'item', Item, ItemCollection
  model.register 'mob', Mob, MobCollection
  model.register 'room', Room, RoomCollection
  model.register 'user', User, UserCollection
  model.register 'world', World, WorldCollection

  world = new model.models.world()
  startup = ->
    debug 'Starting up world'
    world.startup (err) ->
      return register err if err?
      register null,
        model: model
        world: world

  world.fetch
    error: (model, err, options) ->
      debug 'Error while fetching world: %s %j', err, err
      if err instanceof storage.NotFoundError
        debug 'Got %s when trying to fetch world, creating a new one'
        return startup()

      log.error "Could not fetch world: #{err.stack}"
      register err
    success: startup
