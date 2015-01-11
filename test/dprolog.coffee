should = require('chai').should()
DProlog = require '../src/dprolog'

describe 'DParser', ->
    it 'should parse a fact', ->
        kb = DProlog.parseKb "likes(X, pomegranate)."
        kb.should.have.length 1
        kb[0].belief.should.equal 1
        kb[0].head.functor.should.equal "likes"
        kb[0].head.params.should.have.length 2
        kb[0].head.params[0].name.should.equal "X"
        kb[0].head.params[1].functor.should.equal "pomegranate"
    it 'should parse a defeasible rule', ->
        kb = DProlog.parseKb "trans: likes(X, Z) :- likes(X, Y), likes(Y, Z) 0.5."
        kb.should.have.length 1
        kb[0].belief.should.equal 0.5
        kb[0].label.functor.should.equal "trans"
        kb[0].body.should.have.length 2
        kb[0].body[1].functor.should.equal "likes"
        kb[0].body[1].params.should.have.length 2
        kb[0].body[1].params[1].name.should.equal "Z"
    it 'should parse a query', ->
        q = DProlog.parseQuery '~flies(tweety)'
        q.should.have.length 1
        q[0].functor.should.equal "~flies"
        q[0].params.should.have.length 1
        q[0].params[0].functor.should.equal "tweety"

describe 'DProlog', ->
    it 'should match terms and belief', ->
        kb = DProlog.parseKb "english(jack) 0.5. english(jill) 0.6."
        query = DProlog.parseQuery "english(X)"
        iter = DProlog.solve kb, query
        results = []
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal true
        results.push iter.next().toAnswerString()
        iter.hasNext().should.equal false
        # check a second time to make sure emptied state is properly recorded
        iter.hasNext().should.equal false 
        results.should.include 'english(jack) 0.5.'
        results.should.include 'english(jill) 0.6.'

    it 'should use rules', ->
        kb = DProlog.parseKb "bird(tweety).
            penguin(tweety).
            flies(Y) :- bird(Y) 0.9.
            ~flies(Y) :- penguin(Y)."
        query = DProlog.parseQuery "flies(tweety)"
        iter = DProlog.solve kb, query
        iter.hasNext().should.equal true
        result = iter.next().toAnswerString()
        result.should.equal 'flies(tweety) 0.9.'
        iter.hasNext().should.equal false
        query = DProlog.parseQuery "~flies(tweety)"
        iter = DProlog.solve kb, query
        iter.hasNext().should.equal true
        result = iter.next().toAnswerString()
        result.should.equal '~flies(tweety).'
        iter.hasNext().should.equal false
