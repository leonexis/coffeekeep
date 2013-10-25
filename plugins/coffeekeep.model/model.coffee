{Area, AreaCollection} = require './area'
{Model, Collection} = require './base'
{Item, ItemCollection} = require './item'
{Mob, MobCollection} = require './mob'
{Room, RoomCollection} = require './room'
{User, UserCollection} = require './user'
{World, WorldCollection} = require './world'

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

    model = new ModelPlugin options, imports
    model.register 'area', Area, AreaCollection
    model.register 'item', Item, ItemCollection
    model.register 'mob', Mob, MobCollection
    model.register 'room', Room, RoomCollection
    model.register 'user', User, UserCollection
    model.register 'world', World, WorldCollection

    world = new model.models.world()
    world.fetch
        error: (err) ->
            log.error "Could not fetch world: #{err.stack}"
            register err
        success: ->
            world.startup (err) ->
                return register err if err?
                register null,
                    model: model
                    world: world
