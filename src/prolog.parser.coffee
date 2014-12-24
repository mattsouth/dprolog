Prolog = require './prolog'

class exports.Tokeniser
    constructor: (@remainder) ->
        @current = null
        @type = null
        @consume()

    consume: () ->
        return if @type is "eof"        
        # eat any leading white space
        r = @remainder.match /^\s*(.*)$/
        @remainder = r[1] if r?
        # check for eof
        if @remainder is ""
            @current = null
            @type = "eof"
            return
        matcher = (regex, type) =>
            r = @remainder.match regex
            if r
                @remainder = r[2]
                @current = r[1]
                @type = type
                true
            else
                false
        return if matcher /^([\(\)\.,\[\]\|\!]|\:\-)(.*)$/, "punc"
        return if matcher /^([A-Z_][a-zA-Z0-9_]*)(.*)$/, "var"
        return if matcher /^(\{[^\}]*\})(.*)$/, "id"
        return if matcher /^("[^"]*")(.*)$/, "id"
        return if matcher /^([a-zA-Z0-9][a-zA-Z0-9_]*)(.*)$/, "id"
        return if matcher /^(-[0-9][0-9]*)(.*)$/, "id"
        # catch all
        @current = null
        @type = "eof"


