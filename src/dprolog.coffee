###
A prolog interpreter that expects rules to have beliefs
handles them during reasoning so that proofs have them too.
###

# an environment is a set of substitutions
addBinding = (env, name, value) ->
    for own key of env
        env[key] = env[key].rewrite(name: value)
    env[name] = value

# Javascript Array is used for Rule.body and Term.params
Array.prototype.rewrite = (env) ->
    item.rewrite(env) for item in @
Array.prototype.rename = (suffix) ->
    item.rename(suffix) for item in @
Array.prototype.toAnswerString = () ->
    (item.toAnswerString() for item in @).join(", ")

class exports.Var
    constructor: (@name) ->
    rename: (name) -> new Var(@name+name)
    rewrite: (env) -> env[@name] || @
    unify: (that, env) -> 
        if env[@name] 
            env[@name].unify(that, env)
        else
            addBinding(env, @name, that.rewrite(env))
    toAnswerString: -> @name

class exports.Term
    constructor: (@functor, @params = []) ->
    rename: (name) ->
        new exports.Term @functor, (x.rename(name) for x in @params)
    rewrite: (env) ->
        new exports.Term @functor, (x.rewrite(env) for x in @params)
    unify: (that, env) ->
        if that instanceof exports.Term
            return false if that.params.length isnt @params.length or that.functor isnt @functor
            @params.every (param, idx) ->
                param.unify that.params[idx], env
        else
            that.unify this, env
    isGround: ->
        @params.length is 0 or @params.every (param) ->
            not(param instanceof exports.Var) and param.isGround()
    toAnswerString: ->
        "#{@functor}#{if @params.length>0 then "(" + (x.toAnswerString() for x in @params).join(", ") + ")" else ""}"

class exports.Rule
    constructor: (@head, @body=[], @belief=1.0, @label) ->
    rename: (name) -> new Rule @head.rename(name), @body.rename(name)
    toAnswerString: -> "#{@head.toAnswerString()}#{if @body.length>0 then " :- " + @body.toAnswerString() else ""}#{if @belief isnt 1 then " #{@belief}" else ""}."

# tracks updated version of query and subsidiary goals
class State
    constructor: (@query, @goals, @belief=1.0) ->

class Solver
    constructor: (@rules, query) ->
        @suffix = 0
        @empty = false
        # rename call in next line is cheap clone
        @stateStack = [new State(query, query.rename(""))]

    next: -> @solution || throw 'solution only available after hasNext() returns true'

    hasNext: ->
        unless @empty 
            while true
                # an empty stack means no more solutions
                if @stateStack.length==0
                    @empty = true
                    @solution = null
                    return false
                # check stack for any solutions
                for state, idx in @stateStack
                    if state.goals.length == 0
                        @solution = new exports.Rule state.query, [], state.belief
                        @stateStack.splice idx, 1
                        @suffix++
                        return true
                # else update the stack
                state = @stateStack.pop()
                query = state.query
                goals = state.goals
                goal = goals.pop()
                for rule in @rules
                    localised = rule.rename(@suffix)
                    env={}
                    if localised.head.unify goal, env
                        newQuery = query.rewrite(env)
                        newGoals = goals.rewrite(env)
                        newBody = localised.body.rewrite(env)
                        newGoals.push(term) for term in newBody by -1
                        # weakest link
                        belief = if rule.belief < state.belief then rule.belief else state.belief
                        @stateStack.push(new State(newQuery, newGoals, belief))
        false # if @empty

# query: an array of terms
# kb: an array of rules
exports.solve = (rules, query) -> new Solver(rules, query)

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
        return if matcher "punc", /^([\(\)\.,\[\]\|\!]|\:\-|\:)(.*)$/
        return if matcher "bel", /^(1\.0|1|0\.\d*)(.*)$/
        return if matcher "id", /^(\{[^\}]*\})(.*)$/
        return if matcher "var", /^([A-Z_][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^("[^"]*")(.*)$/
        return if matcher "id", /^([a-zA-Z0-9~][a-zA-Z0-9_]*)(.*)$/
        return if matcher "id", /^(-[0-9][0-9]*)(.*)$/
        # bail if our rules havent identified the next token
        @current = null
        @type = "eof"

# Note that facts are rules without bodies
parseRule = (tk) ->
    getBelief = () ->
        if tk.type is "bel"
            belief = parseFloat tk.current
            tk.consume()
            return belief
        else 
            1.0
    headorlabel = parseTerm(tk)
    return unless headorlabel?
    if tk.current is ":"
        label = headorlabel
        # todo: ensure label is an atom, i.e. a term with no params
        tk.consume()
        head = parseTerm(tk)
    else
        head = headorlabel
    if tk.current is "." or tk.type is "bel"
        return null if label?
        return new exports.Rule head, [], getBelief()
    return null if tk.current isnt ":-"
    tk.consume()
    body = parseList(tk)
    belief = getBelief()
    return null if tk.current isnt "."
    return new exports.Rule head, body, belief, label

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

# a query is a list of terms
exports.parseQuery = (query) ->
    parseList new Tokeniser(query)