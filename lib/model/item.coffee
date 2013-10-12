{Model, Collection} = require './'

class Item extends Model
    defaults: ->
        keywords: ""
        shortDescription: ""
        longDescription: ""
        weight: 0
        cost: 0
        extras: []
        effects: []

    initialize: ->

    toString: ->
        "[Item #{@id}]"
            
class ItemCollection extends Collection
    model: Item
    urlPart: 'items'

exports.Item = Item
exports.ItemCollection = ItemCollection