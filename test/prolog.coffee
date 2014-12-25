should = require('chai').should()
Prolog = require '../src/prolog'
Parser = require '../src/prolog.parser'

describe 'Parser', ->
    it 'should parse a ground predicate', ->
        kb = Parser.parseKb "father(abraham, esau)."
        kb.should.have.length 1
    it 'should parse a non-ground predicate', ->
        kb = Parser.parseKb "likes(X, pomegranate)."
        kb.should.have.length 1
    it 'should parse a rule', ->
        kb = Parser.parseKb "likes(X, Z) :- likes(X, Y), likes(Y, Z)."
        kb.should.have.length 1
    it 'should parse a query', ->
        q = Parser.parseQuery 'a, b'
        q.should.have.length 2
###
describe 'Prolog', ->

    it 'should unify clauses', ->
        kb = [
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('english'), new Prolog.List(new Prolog.Symbol('jack'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('english'), new Prolog.List(new Prolog.Symbol('jill'))), new Prolog.List())
            ]
        query = new Prolog.Clause(new Prolog.Symbol('english'), new Prolog.List(new Prolog.Var('X')))
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
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('grandfather'), new Prolog.List(new Prolog.Var('X'), new Prolog.Var('Y'))), 
                new Prolog.List(new Prolog.Clause(new Prolog.Symbol('father'), new Prolog.List(new Prolog.Var('X'), new Prolog.Var('Z'))), 
                new Prolog.Clause(new Prolog.Symbol('father'), new Prolog.List(new Prolog.Var('Z'), new Prolog.Var('Y'))))),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('father'), new Prolog.List(new Prolog.Symbol('abe'), new Prolog.Symbol('homer'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('father'), new Prolog.List(new Prolog.Symbol('homer'), new Prolog.Symbol('lisa'))), new Prolog.List()),
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('father'), new Prolog.List(new Prolog.Symbol('homer'), new Prolog.Symbol('bart'))), new Prolog.List())
            ]
        query = new Prolog.Clause(new Prolog.Symbol('grandfather'), new Prolog.List(new Prolog.Symbol('abe'), new Prolog.Var('X')))
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

    it 'should recurse (infinitely if you let it)', ->
        kb = [
            new Prolog.Rule(new Prolog.Clause(new Prolog.Symbol('nat'), new Prolog.List(new Prolog.Symbol('z'))), new Prolog.List()),
            new Prolog.Rule(
                new Prolog.Clause(new Prolog.Symbol('nat'), new Prolog.List(new Prolog.Clause(new Prolog.Symbol('s'), new Prolog.List(new Prolog.Var('X'))))),
                new Prolog.List(new Prolog.Clause(new Prolog.Symbol('nat'), new Prolog.List(new Prolog.Var('X')))))
            ]
        query = new Prolog.Clause(new Prolog.Symbol('nat'), new Prolog.List(new Prolog.Var('Y')))
        iter = Prolog.solve(query, kb)
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(z)"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(z))"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(s(z)))"
        # ad infinitum ...
###