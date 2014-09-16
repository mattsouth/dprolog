should = require('chai').should()
Prolog = require '../src/dprolog'

describe 'Prolog', ->

    it 'should unify clauses', ->
        kb = [
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('english'), new Prolog.List(new Prolog.Sym('jack'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('english'), new Prolog.List(new Prolog.Sym('jill'))), new Prolog.List())
            ]
        query = new Prolog.Clause(new Prolog.Sym('english'), new Prolog.List(new Prolog.Var('X')))
        iter = Prolog.solve(query, kb)
        results = []
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal false
        # check a second time to make sure emptied state is properly recorded
        iter.hasNext().should.equal false 
        results.should.include 'english(jack)'
        results.should.include 'english(jill)'

    it 'should unify rules', ->
        kb = [
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('grandfather'), new Prolog.List(new Prolog.Var('X'), new Prolog.Var('Y'))), 
                new Prolog.List(new Prolog.Clause(new Prolog.Sym('father'), new Prolog.List(new Prolog.Var('X'), new Prolog.Var('Z'))), 
                new Prolog.Clause(new Prolog.Sym('father'), new Prolog.List(new Prolog.Var('Z'), new Prolog.Var('Y'))))),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('father'), new Prolog.List(new Prolog.Sym('abe'), new Prolog.Sym('homer'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('father'), new Prolog.List(new Prolog.Sym('homer'), new Prolog.Sym('lisa'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Sym('father'), new Prolog.List(new Prolog.Sym('homer'), new Prolog.Sym('bart'))), new Prolog.List())
            ]
        query = new Prolog.Clause(new Prolog.Sym('grandfather'), new Prolog.List(new Prolog.Sym('abe'), new Prolog.Var('X')))
        iter = Prolog.solve(query, kb)
        results = []
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal false
        # check a second time to make sure emptied state is properly recorded
        iter.hasNext().should.equal false 
        results.should.include 'grandfather(abe, lisa)'
        results.should.include 'grandfather(abe, bart)'

    ###
    it 'should recurse (infinitely if you let it)', ->
        kb = [
            new Prolog.Rule(
                new Prolog.Clause(new Prolog.Sym('nat'), new Prolog.List(new Prolog.Sym('z'))), 
                new Prolog.List()),
            new Prolog.Rule(
                new Prolog.Clause(new Prolog.Sym('nat'), new Prolog.List(new Prolog.Clause(new Prolog.Sym('s'), new Prolog.List(new Prolog.Var('X'))))),
                new Prolog.List(new Prolog.Clause(new Prolog.Sym('nat'), new Prolog.List(new Prolog.Var('X')))))
            ]
        query = new Prolog.Clause(new Prolog.Sym('nat'), new Prolog.List(new Prolog.Var('Y')))
        iter = Prolog.solve(query, kb)
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(z)"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(z))"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(s(z)))"
        # ad infinitum ...
    ###