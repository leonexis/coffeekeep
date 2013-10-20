{Model, Collection} = require './base'

class Item extends Model
    defaults: ->
        name: ""
        shortDescription: ""
        description: ""
        weight: 0
        cost: 0
        extras: []
        affects: []

    initialize: ->

    toString: ->
        "[Item #{@id}]"
            
class ItemCollection extends Collection
    model: Item
    urlPart: 'items'

exports.Item = Item
exports.ItemCollection = ItemCollection