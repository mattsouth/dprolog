/*
  Copyright (c) 2007 Alessandro Warth <awarth@cs.ucla.edu> and Stephen Murrell <stephen@rabbit.eng.miami.edu>

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the "Software"), to deal in the Software without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.
*/


function Sym(name) { this.name = name }
Sym.prototype.rename  = function(nm)  { return this }
Sym.prototype.rewrite = function(env) { return this }
Sym.prototype.toAnswerString = function() { return this.name }

function Var(name) { this.name = name }
Var.prototype.rename  = function(nm)  { return new Var(this.name + nm) }
Var.prototype.rewrite = function(env) { return env[this.name] ? env[this.name] : this }
Var.prototype.toAnswerString = function() { return this.name }

function Clause(sym, args) { this.sym  = sym; this.args = args }
Clause.prototype.rename  = function(nm)  { return new Clause(this.sym, this.args.map(function(x) { return x.rename(nm) })) }
Clause.prototype.rewrite = function(env) { return new Clause(this.sym, this.args.map(function(x) { return x.rewrite(env) })) }
Clause.prototype.toAnswerString = function() {
  return this.sym.toAnswerString() + "(" + this.args.map(function(x) { return x.toAnswerString() }).join(", ") + ")"
}

Array.prototype.rename  = function(n)   { return this.map(function(x) { return x.rename(n) }) }
Array.prototype.rewrite = function(env) { return this.map(function(x) { return x.rewrite(env) }) }
Array.prototype.toAnswerString = function() { return this.map(function(x) { return x.toAnswerString() }).join(", ") }

function Rule(head, clauses) { this.head = head; this.clauses = clauses }
Rule.prototype.rename  = function(n)   { return new Rule(this.head.rename(n), this.clauses.rename(n)) }

function addBinding(env, name, value) {
  var subst = {}
  subst[name] = value
  for (var n in env)
    if (env.hasOwnProperty(n))
      env[n] = env[n].rewrite(subst)
  env[name] = value
}
function assert(cond) { if (!cond) throw "unification failed" }

Sym.prototype.unify = function(that, env) {
  if (that instanceof Sym)
    assert(this.name == that.name)
  else {
    assert(that instanceof Var)
    if (env[that.name])
      this.unify(env[that.name], env)
    else
      addBinding(env, that.name, this.rewrite(env))
  }
}
Var.prototype.unify = function(that, env) {
  if (env[this.name])
    env[this.name].unify(that, env)
  else
    addBinding(env, this.name, that.rewrite(env))
}
Clause.prototype.unify = function(that, env) {
  console.log('clause.unify', this.toAnswerString(), that.toAnswerString(), env);
  if (that instanceof Clause) {
    assert(that.args.length == this.args.length)
    this.sym.unify(that.sym, env)
    for (var idx = 0; idx < this.args.length; idx++)
      this.args[idx].unify(that.args[idx], env)
  }
  else
    that.unify(this, env)
}

function State(query, goals) { this.query = query; this.goals = goals }

function nextSolution(nameMangler, rules, stateStack) {
  while (true) {
    if (stateStack.length == 0)
      return false
    var state = stateStack.pop(),
        query = state.query,
        goals = state.goals
    if (goals.length == 0)
      return !window.confirm(query.toAnswerString())
    var goal = goals.pop()
    for (var idx = rules.length - 1; idx >= 0; idx--) {
      var rule = rules[idx].rename(nameMangler), env
      try { rule.head.unify(goal, env = {}) }
      catch (e) { continue }
      var newQuery = query.rewrite(env),
          newGoals = goals.rewrite(env),
          newBody  = rule.clauses.rewrite(env)
      for (var idx2 = newBody.length - 1; idx2 >= 0; idx2--)
        newGoals.push(newBody[idx2])
      stateStack.push(new State(newQuery, newGoals))
    }
  }
}

function solve(query, rules) {
  var stateStack = [new State(query, [query])], n = 0
  while (nextSolution(n++, rules, stateStack)) {}
  alert("no more solutions")
}


/*
A couple of examples:

solve(
  new Clause(new Sym("nat"), [new Var("X")]),
  [new Rule(new Clause(new Sym("nat"), [new Sym("z")]), []),
   new Rule(new Clause(new Sym("nat"), [new Clause(new Sym("s"), [new Var("X")])]),
            [new Clause(new Sym("nat"), [new Var("X")])])]
)

solve(
  new Clause(new Sym("grandfather"), [new Sym("abe"), new Var("X")]),
  [new Rule(new Clause(new Sym("grandfather"), [new Var("X"), new Var("Y")]),
            [new Clause(new Sym("father"), [new Var("X"), new Var("Z")]),
             new Clause(new Sym("father"), [new Var("Z"), new Var("Y")])]),
   new Rule(new Clause(new Sym("father"), [new Sym("abe"), new Sym("homer")]), []),
   new Rule(new Clause(new Sym("father"), [new Sym("homer"), new Sym("lisa")]), []),
   new Rule(new Clause(new Sym("father"), [new Sym("homer"), new Sym("bart")]), [])]
)

solve(
  new Clause(new Sym("english"), [new Var("X")]),
  [new Rule(new Clause(new Sym("english"), [new Sym("jim")]), [])]
)
*/
