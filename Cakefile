{spawn, exec} = require 'child_process'

# Terminal colurs
bold  = '\x1B[0;1m'
red   = '\x1B[0;31m'
green = '\x1B[0;32m'
blue  = '\x1B[0;36m'
reset = '\x1B[0m'

####################
# HELPER FUNCTIONS #
####################

log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

task 'build', 'Build', ->
    # Build the coffee files
    log 'Building coffee files', blue
    build = spawn "./node_modules/.bin/coffee", "-c ./src ./test".split(" ")
    build.stdout.pipe process.stdout
    build.stderr.pipe process.stderr

task 'test', 'Build and run test suite', ->

    # Build the coffee files
    log 'Building coffee files', blue
    build = spawn "./node_modules/.bin/coffee", "-c ./src ./test".split(" ")
    build.stdout.pipe process.stdout
    build.stderr.pipe process.stderr
    build.on 'exit', (code) ->

         # Check for error
        if code is 0
            log 'Running test suite', blue
            test = spawn "./node_modules/.bin/mocha", "--reporter spec --timeout 300000 ./test".split(" ")
            test.stdout.pipe process.stdout
            test.stderr.pipe process.stderr
        else
            log '- Build failed', red
