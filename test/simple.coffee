should = require('chai').should()
Prolog = require '../src/simple'

describe 'Simple Parser', ->
    it 'should parse a fact', ->
        kb = Prolog.parseKb "likes(X, pomegranate)."
        kb.should.have.length 1
        kb[0].head.functor.should.equal "likes"
        kb[0].head.params.should.have.length 2
        kb[0].head.params[0].name.should.equal "X"
        kb[0].head.params[1].functor.should.equal "pomegranate"
    it 'should parse a rule', ->
        kb = Prolog.parseKb "likes(X, Z) :- likes(X, Y), likes(Y, Z)."
        kb.should.have.length 1
        kb[0].body.should.have.length 2
        kb[0].body[1].functor.should.equal "likes"
        kb[0].body[1].params.should.have.length 2
        kb[0].body[1].params[1].name.should.equal "Z"
    it 'should parse a query', ->
        q = Prolog.parseQuery 'a'
        q.functor.should.equal "a"

describe 'Simple Interpreter', ->
    it 'should correctly answer ground query', ->
        kb = Prolog.parseKb "father(abraham, isaac).
            father(haran, lot).
            father(haran, milcah).
            father(haran, yischa).
            male(isaac).
            male(lot).
            female(milcah).
            female(yiscah).
            son(X, Y) :- father(Y, X), male(X).
            daughter(X, Y) :- father(Y, X), female(X)."
        query = Prolog.parseQuery "son(lot, haran)"
        Prolog.solve(query, kb).should.equal true
        query = Prolog.parseQuery "son(milcah, haran)"
        Prolog.solve(query, kb).should.equal false
    it 'shouldnt accept a non-ground query', ->
        kb = Prolog.parseKb "resistor(power, n1(2))."
        query = Prolog.parseQuery "resistor(power, n1(X))"
        # todo: Prolog.solve(query, kb).should.throw 'cannot...'
        try
            Prolog.solve(query, kb)
        catch e
            e.should.equal 'cannot interpret a non-ground query'