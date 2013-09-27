###
Augment a Backbone Model to use sqlite as the backend storage
###
path = require 'path'

exports.config = config =
    database: path.resolve __dirname + '/../../../coffeekeep.sqlite'
    verbose: true
    
exports.enable = (Model, Collection) ->
    sqlite3 = require 'sqlite3' # Lazy load
    util = require 'util'
    _ = require 'underscore'
    
    do sqlite3.verbose
    
    db = new sqlite3.Database config.database
    
    db.serialize ->
        db.run "CREATE TABLE IF NOT EXISTS objects (url PRIMARY KEY, json)"
    
    Model::sync = (method, model, options) ->
        options ?= {}
        
        url = _.result model, 'url'
        
        console.log "SYNC: #{url}: #{method}, #{util.inspect model}, #{util.inspect options}"
        if not url?
            throw new Error "Could not get url for this model #{util.inspect model}"
        
        switch method
            when 'create', 'update'
                obj = JSON.stringify model.attributes
                db.run "UPDATE objects SET json = ? WHERE url = ?", obj, url, (err) ->
                    if err?
                        console.error "Error while updating #{util.inspect [model, options, err]}"
                        return options.error? err
                    
                    # Callback 'this' is the statement object
                    if @changes == 0
                        # No original object to update, insert instead
                        console.log "No changes made during UPDATE, assuming object at #{url} needs to be created"
                        db.run "INSERT INTO objects VALUES (?, ?)", url, obj, (err) ->
                            if err?
                                console.error "Error while creating #{util.inspect err}"
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
                                console.error "Error while reading multiple #{util.inspect [model, options, err]}"
                                return options.error? err
                            out = []
                            for row in rows
                                out.push JSON.parse row.json
                            options.success? out
                else
                    # Read a single object
                    db.get "SELECT url, json FROM objects WHERE url = ?", url, (err, row) ->
                        if err?
                            console.error "Error while reading single #{util.inspect [model, options, err]}"
                            return options.error? err
                            
                        if not row?
                            return options.success? null
                        
                        options.success JSON.parse row.json
                            
            when 'delete'
                db.run "DELETE FROM objects WHERE url = ?", url, (err) ->
                    if err?
                        console.error "Error during delete: #{util.inspect [model, options, err]}"
                        return options.error? err
                    options.success? null
                    
        model.trigger 'request', model, null, options
        null
    
    Collection::sync = Model::sync