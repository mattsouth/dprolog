Prolog = require './prolog'

# a programme is an array of rules
exports.parseKb = (program) ->
    tk = new exports.Tokeniser(program)
    kb = []
    until tk.type is "eof"
        kb.push exports.parseRule(tk)
        tk.consume()
    kb

# a query is an array of clauses
exports.parseQuery = (query) ->
    exports.parseBody new exports.Tokeniser(query)

class exports.Tokeniser
    constructor: (@remainder) ->
        @current = null
        @type = null
        @consume()

    consume: () ->
        # get next token
        matcher = (type, regex) =>
            r = @remainder.match regex
            if r
                @remainder = r[2]
                @current = r[1]
                @type = type
                true
            else
                false
        # return if we've previously reached eof
        return if @type is "eof"
        # eat any leading white space
        r = @remainder.match /^\s*(.*)$/
        @remainder = r[1] if r?
        # and check for eof
        if @remainder is ""
            @current = null
        return if matcher "punc", /^([\(\)\.,\[\]\|\!]|\:\-)(.*)$/
        return if matcher "var", /^([A-Z_][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^(\{[^\}]*\})(.*)$/
        return if matcher "id", /^("[^"]*")(.*)$/
        return if matcher "id", /^([a-zA-Z0-9][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^(-[0-9][0-9]*)(.*)$/
        # bail if our rules havent identified the next token
        @current = null
        @type = "eof"

exports.parseRule = (tk) ->
    head = exports.parseTerm(tk)
    return unless head?
    return new Prolog.Rule(head) if tk.current is "."
    return null if tk.current isnt ":-"
    tk.consume()
    body = exports.parseBody(tk)
    return null if tk.current isnt "."
    return new Prolog.Rule(head, body)

exports.parseBody = (tk) ->
    p = new Prolog.List
    loop
        t = exports.parseTerm(tk)
        return null if t is null
        p.push t 
        break if tk.current isnt ","
        tk.consume()
    return p

# Term -> id ( optParamList )        
exports.parseTerm = (tk) ->
    return null if tk.type isnt "id"
    functor = tk.current
    tk.consume()
    if tk.current isnt "("
        return new Prolog.Symbol(functor)
    tk.consume()
    p = new Prolog.List()
    while tk.current isnt ")"
        return null if tk.type is "eof"
        part = exports.parsePart(tk)
        return null if part is null
        if tk.current is ","
            tk.consume()
        else
            return null if tk.current isnt ")"
        p.push part
    tk.consume()
    return new Prolog.Clause(new Prolog.Symbol(functor), p)   

# Part -> var | symbol | clause
exports.parsePart = (tk) ->
    if tk.type is "var"
        name = tk.current
        tk.consume()
        return new Prolog.Var(name)
    else
        functor = tk.current
        tk.consume()
        return new Prolog.Symbol(functor) if tk.current isnt "("
        tk.consume()

        params = new Prolog.List
        while tk.current isnt ")"
            return null if tk.type is "eof"
            param = exports.parsePart(tk)
            return null if param is null
            if tk.current is ","
                tk.consume()
            else 
                return null if tk.current isnt ")"
            params.push param
        tk.consume()
        return new Prolog.Clause(new Prolog.Symbol(functor), params)