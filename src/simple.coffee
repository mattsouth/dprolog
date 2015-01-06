###
A simple prolog interpreter, based on algorithm outlined 
on page 12 of The Art of Prolog (Sterling and Shapiro).
###

# an environment is a set of substitutions
addBinding = (env, name, value) ->
    for own key of env
        env[key] = env[key].rewrite(name: value)
    env[name] = value

# [] used for Rule.body and Term.params
Array.prototype.rewrite = (env) ->
    item.rewrite(env) for item in @

class exports.Term
    constructor: (@functor, @params = []) ->
    rewrite: (env) ->
        new exports.Term @functor, (x.rewrite(env) for x in @params)
    unify: (that, env) ->
        return false if that.params.length isnt @params.length or that.functor isnt @functor
        @params.every (param, idx) ->
            param.unify that.params[idx], env
    isGround: ->
        @params.length is 0 or @params.every (param) ->
            not(param instanceof exports.Var) and param.isGround()
    toAnswerString: ->
        "#{@functor}#{if @params.length>0 then "(" + (x.toAnswerString() for x in @params).join(", ") + ")" else ""}"

class exports.Rule
    constructor: (@head, @body = []) ->
    toAnswerString: -> 
        "#{@head.toAnswerString()}#{if @body.length>0 then " :- " + (x.toAnswerString() for x in @body).join(", ") else ""}."

class exports.Var
    constructor: (@name) ->
    rewrite: (env) -> env[@name] || @
    unify: (that, env) -> 
        if env[@name] 
            env[@name].unify that, env 
        else
            addBinding env, @name, that.rewrite(env)
    toAnswerString: -> @name

# query a ground term against the provided kb/program
# query = a single ground term
# kb = an array of rules
exports.solve = (query, kb) -> 
    if not query.isGround()
        throw 'cannot interpret a non-ground query'
    resolvent = [query]
    while true
        if resolvent.length is 0 
            return true
        goal = resolvent.pop()
        continue if kb.some (rule) =>
            env = {}
            if rule.head.unify goal, env
                newBody = rule.body.rewrite(env)
                resolvent.push(term) for term in newBody
                true
            else
                false
        return false # goal could not be matched

###############################################################################
# Parser
###############################################################################

class Tokeniser
    constructor: (@remainder) ->
        @current = null
        @type = null
        @consume()

    # get next token
    consume: () ->
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
        # looking good: grab next token
        return if matcher "punc", /^([\(\)\.,\[\]\|\!]|\:\-)(.*)$/
        return if matcher "var", /^([A-Z_][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^(\{[^\}]*\})(.*)$/
        return if matcher "id", /^("[^"]*")(.*)$/
        return if matcher "id", /^([a-zA-Z0-9][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^(-[0-9][0-9]*)(.*)$/
        # bail if our rules havent identified the next token
        @current = null
        @type = "eof"

parseRule = (tk) ->
    head = parseTerm(tk)
    return unless head?
    return new exports.Rule(head) if tk.current is "."
    return null if tk.current isnt ":-"
    tk.consume()
    body = parseList(tk)
    return null if tk.current isnt "."
    return new exports.Rule(head, body)

parseList = (tk) ->
    list = []
    loop
        term = parseTerm(tk)
        return null if term is null
        list.push term 
        break if tk.current isnt ","
        tk.consume()
    return list

# Term -> id ( optParamList )        
parseTerm = (tk) ->
    return null if tk.type isnt "id"
    functor = tk.current
    tk.consume()
    if tk.current isnt "("
        return new exports.Term(functor)
    tk.consume()
    params = []
    while tk.current isnt ")"
        return null if tk.type is "eof"
        param = parsePart(tk)
        return null if param is null
        if tk.current is ","
            tk.consume()
        else
            return null if tk.current isnt ")"
        params.push param
    tk.consume()
    return new exports.Term(functor, params)   

# Part -> var | term
parsePart = (tk) ->
    if tk.type is "var"
        name = tk.current
        tk.consume()
        return new exports.Var(name)
    else
        functor = tk.current
        tk.consume()
        return new exports.Term(functor) if tk.current isnt "("
        tk.consume()

        params = []
        while tk.current isnt ")"
            return null if tk.type is "eof"
            param = parsePart(tk)
            return null if param is null
            if tk.current is ","
                tk.consume()
            else 
                return null if tk.current isnt ")"
            params.push param
        tk.consume()
        return new exports.Term(functor, params)

# a Knowledgebase is an array of rules
exports.parseKb = (program) ->
    tk = new Tokeniser(program)
    kb = []
    until tk.type is "eof"
        kb.push parseRule(tk)
        tk.consume()
    kb

# a query is a single term
exports.parseQuery = (query) ->
    parseTerm new Tokeniser(query)