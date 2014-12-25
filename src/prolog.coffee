assert = (cond) -> if !cond then throw "unification failed"

addBinding = (env, name, value) ->
    subst = name: value
    for own key of env
        env[key] = env[key].rewrite(subst)
    env[name] = value

# a Symbol is a constant - it cannot be renamed or rewritten
class exports.Symbol
    constructor: (@name) ->
    rename: (name) -> @
    rewrite: (env) -> @
    unify: (that, env) ->
        if that instanceof Symbol
            assert(@name==that.name)
        else 
            assert (that instanceof exports.Var)
            if env[that.name]
                @unify(env[that.name], env)
            else 
                addBinding(env, that.name, @rewrite(env))
    toAnswerString: -> @name

# a Var is a bindable Symbol
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

# a Clause has a symbol functor and a list of arguments
class exports.Clause
    constructor: (@sym, @args) ->
    rename: (name) ->
        new Clause @sym, (x.rename(name) for x in @args)
    rewrite: (env) ->
        new Clause @sym, (x.rewrite(env) for x in @args)
    unify: (that, env) ->
        console.log 'clause.unify', @toAnswerString(), that.toAnswerString(), env
        if that instanceof Clause
            assert(that.args.length == this.args.length)
            @sym.unify(that.sym, env)
            arg.unify(that.args[idx], env) for arg, idx in @args
        else
            that.unify(@, env)
    toAnswerString: ->
        "#{@sym.toAnswerString()}(#{(x.toAnswerString() for x in @args).join(", ")})"

class exports.List extends Array
    constructor: ->
        @push arguments...
    rename: (name) -> 
        list = new exports.List
        list.push x.rename(name) for x in @
        list
    rewrite: (env) -> 
        list = new exports.List
        list.push x.rewrite(env) for x in @
        list
    toAnswerString: -> "[List " + (@map (x) -> x.toAnswerString()).join(", ") + "]"

class exports.Rule
    constructor: (@head, @clauses) ->
    rename: (name) -> new Rule @head.rename(name), @clauses.rename(name)
    toAnswerString: -> "#{@head.toAnswerString()}#{if @clauses.length>0 then " :- " + (x.toAnswerString() for x in @clauses).join(", ") else ""}."

class State
    constructor: (@query, @goals) ->

class Solver
    constructor: (@rules, @stateStack) ->
        @nameMangler=0
        @empty = false

    next: -> @solution || throw 'solution only available after hasNext() returns true'

    hasNext: ->
        if !@empty 
            while true
                if @stateStack.length==0
                    @empty = true
                    @solution = null
                    return false
                state = @stateStack.pop()
                query = state.query
                goals = state.goals
                if goals.length==0
                    @solution = query
                    @nameMangler++
                    return true
                goal = goals.pop()
                for rule in @rules
                    mangled = rule.rename(@nameMangler)
                    env = {}
                    try
                        mangled.head.unify goal, env
                    catch e
                        continue
                    newQuery = query.rewrite(env)
                    newGoals = goals.rewrite(env)
                    newBody = mangled.clauses.rewrite(env)
                    newGoals.push(cl) for cl in newBody by -1
                    @stateStack.push(new State(newQuery, newGoals))
        else
            false

exports.solve = (query, rules) -> new Solver(rules, [new State(query, new exports.List(query))])
