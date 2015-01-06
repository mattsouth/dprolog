should = require('chai').should()
Prolog = require '../src/prolog'

describe 'Parser', ->
    # TODO: test parsing malformed kbs
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
        q = Prolog.parseQuery 'a, b'
        q.should.have.length 2
        q[0].functor.should.equal "a"
        q[1].functor.should.equal "b"

describe 'Prolog', ->
    it 'should match terms', ->
        kb = Prolog.parseKb "english(jack). 
            english(jill)."
        query = Prolog.parseQuery "english(X)"
        iter = Prolog.solve(kb, query)
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

    it 'should use rules', ->
        kb = Prolog.parseKb "grandfather(X,Y) :- father(X,Z), father(Z,Y). 
            father(abe, homer). 
            father(homer, bart). 
            father(homer, lisa)."
        query = Prolog.parseQuery "grandfather(abe, X)"
        iter = Prolog.solve(kb, query)
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
        kb = Prolog.parseKb "nat(z). nat(s(X)) :- nat(X)."
        query = Prolog.parseQuery "nat(Y)"
        iter = Prolog.solve(kb, query)
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(z)"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(z))"
        iter.hasNext().should.equal true
        iter.next().toAnswerString().should.equal "nat(s(s(z)))"
        # ad infinitum ...
