exports.splitFull = (text, sep, maxsplit=-1) ->
    if not sep?
        sep = /(\s+)/
    
    parts = text.split sep
    
    if maxsplit == -1
        return parts
    
    out = []
    splits = 0
    while parts.length > 0 and splits <= maxsplits
        out.push parts.shift()
        parts.shift() if sep instanceof RegExp
    
    if sep instanceof RegExp
        parts = parts.join ''
    else
        parts = parts.join sep
    
    out.push parts
    out