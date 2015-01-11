dprolog
=======

defeasible prolog

An extension of prolog that allows rules to be labelled with a belief (a real number between 0 and 1 inclusive) and given a label so that proofs can be generated with a belief attached to them and rules can argued about.

Based on the argument generation part of Gerard Vreeswijk's Argumentation System, see http://aspic.cossac.org/ArgumentationSystem

Note that simple.coffee and prolog.coffee show the development of the minimalist prolog engine that underlies dprolog.coffee.  Kudos also to jsprolog.js and tiny-prolog.js (see /etc) which also informed development.

TODO: 
* comments handled by parser
* REPL
* numeric built-ins
* strings / lists
* other built-in predicates