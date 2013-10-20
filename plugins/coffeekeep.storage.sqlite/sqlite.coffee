###
Augment a Backbone Model to use sqlite as the backend storage
###
path = require 'path'
sqlite3 = require 'sqlite3'
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
                obj = JSON.stringify model.attributes
                db.run "INSERT INTO objects VALUES (?, ?)", url, obj, (err) ->
                    if err?
                        log.error "Error while creating #{util.inspect err}"
                        return options.error? err
                    options.success? null

            when 'update'
                obj = JSON.stringify model.attributes
                db.run "UPDATE objects SET json = ? WHERE url = ?", obj, url, (err) ->
                    if err?
                        log.error "Error while updating #{util.inspect [model, options, err]}"
                        return options.error? err

                    # Callback 'this' is the statement object
                    if @changes == 0
                        # No original object to update, insert instead
                        log.info "No changes made during UPDATE, assuming object at #{url} needs to be created"
                        db.run "INSERT INTO objects VALUES (?, ?)", url, obj, (err) ->
                            if err?
                                log.error "Error while creating #{util.inspect err}"
                                return options.error? err
                            options.success? null
                    else
                        options.success? null

            when 'read'
                if url[url.length - 1] is '/'
                    # This is a container
                    db.all "SELECT url, json FROM objects WHERE url LIKE ? AND url NOT LIKE ?",
                        url + "%", url + "%/%",
                        (err, rows) ->
                            if err?
                                log.error "Error while reading multiple #{util.inspect [model, options, err]}"
                                return options.error? err
                            out = []
                            for row in rows
                                out.push JSON.parse row.json
                            options.success? out
                else
                    # Read a single object
                    db.get "SELECT url, json FROM objects WHERE url = ?", url, (err, row) ->
                        if err?
                            log.error "Error while reading single #{util.inspect [model, options, err]}"
                            return options.error? err

                        if not row?
                            return options.success? null

                        options.success JSON.parse row.json

            when 'delete'
                db.run "DELETE FROM objects WHERE url = ?", url, (err) ->
                    if err?
                        log.error "Error during delete: #{util.inspect [model, options, err]}"
                        return options.error? err
                    options.success? null

        model.trigger 'request', model, null, options
        null

module.exports = (options, imports, register) ->
    console.assert options.database?, "Must specify database"
    _.defaults options,
        verbose: false
    
    if options.verbose
        sqlite3.verbose()
    
    db = new sqlite3.Database options.database
    db.serialize ->
        db.run "CREATE TABLE IF NOT EXISTS objects (url PRIMARY KEY, json)"
    
    register null,
        storage:
            sync: getSync imports.log, db
