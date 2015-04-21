###
Augment a Backbone Model to use an in-memory key-value store
(mainly for testing)
###
util = require 'util'
_ = require 'underscore'

getSync = (log, db) -> (method, model, options) ->
    options ?= {}

    url = _.result model, 'url'

    log.info("SYNC: #{url}: #{method}, #{model.toString()}, "
             "#{JSON.stringify options}")
    if not url?
        throw new Error "Could not get url for this model #{util.inspect model}"

    switch method
        when 'create'
            if db[url]?
                process.nextTick ->
                    options.error? new Error "Object at #{url} already exists"
                return

            obj = JSON.stringify model.attributes
            db[url] = obj
            process.nextTick ->
                options.success? null

        when 'update'
            unless db[url]?
                process.nextTick ->
                    options.error? new Error "Cannot update non-existant object at #{url}"
                return

            obj = JSON.stringify model.attributes
            db[url] = obj
            process.nextTick ->
                options.success? null

        when 'read'
            if url[url.length - 1] is '/'
                # This is a container
                out = _.chain db
                    .keys()
                    .filter (key) -> key.indexOf(url) == 0
                    .map (key) -> JSON.parse db[key]
                    .value()

                process.nextTick -> options.success? out

            else
                # Read a single object
                out = db[url]
                if _.isUndefined out
                    out = null
                else
                    out = JSON.parse out

                process.nextTick -> options.success? out

        when 'delete'
            if db[url]?
                delete db[url]

            process.nextTick -> options.success? null

    model.trigger 'request', model, null, options
    null

module.exports = (options, imports, register) ->
    _.defaults options,
        verbose: false

    db = {}

    register null,
        storage:
            sync: getSync imports.log, db
            _db: db
