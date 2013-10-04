_ = require 'underscore'

exports.splitFull = (text, sep, maxsplit=-1) ->
    if not sep?
        sep = /(\s+)/

    parts = text.split sep

    if maxsplit == -1
        if _.isRegExp sep
            out = []
            while parts.length > 0
                out.push parts.shift()
                parts.shift()
            return out
        else
            return parts

    out = []
    splits = 0
    while parts.length > 0 and splits <= maxsplits
        out.push parts.shift()
        parts.shift() if _.isRegExp sep

    if sep instanceof RegExp
        parts = parts.join ''
    else
        parts = parts.join sep

    out.push parts
    out