should = require('chai').should()
Prolog = require '../src/prolog'

# NB Prolog parser is identical to Simple parser, hence no tests

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
