spawn = require('child_process').spawn
path = require 'path'

describe 'integration', ->
  Given -> @stdout = ''

  context 'options', ->
    # --no-color, otherwise, the color escape sequences make it hard to assert against the resultant string
    When -> @child = spawn 'grunt', ['simple-test:opts', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'opts --fruit banana --animal tiger --animal moose --multi-word --no-negated -b quux -c --author=Andrew'

  context 'env', ->
    When -> @child = spawn 'grunt', ['simple-test:env', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'env BAR'

  context 'cwd', ->
    When -> @child = spawn 'grunt', ['simple-test:cwd', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal "cwd --cwd #{__dirname}"

  context 'force', ->
    When -> @child = spawn 'grunt', ['simple-test:force', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal "#{__dirname}/fixtures/test.js:force returned code 1. Ignoring..."

  context 'cmd', ->
    When -> @child = spawn 'grunt', ['simple-test:cmd', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'not-cmd'

  context 'args', ->
    When -> @child = spawn 'grunt', ['simple-test:args', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'args jingle bells'

  context 'raw', ->
    When -> @child = spawn 'grunt', ['simple-test:raw', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'raw -- $% "hello" '

  context 'debug', ->
    When -> @child = spawn 'grunt', ['simple-test:debug', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @lines = @stdout.split('\n')
    And -> @command = @lines[1]
    And -> @options = @lines[3]
    And -> @stdout = @lines[ @lines.length - 4 ]
    Then -> expect(@command).to.equal "Command: #{__dirname}/fixtures/test.js debug"
    And -> expect(@options.trim()).to.equal 'Options: { env:'
    And -> expect(@stdout).to.equal '[DEBUG]: stdout'

  context 'debug with stdout', ->
    When -> @child = spawn 'grunt', ['simple-test:stdout', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @lines = @stdout.split('\n')
    And -> @command = @lines[1]
    And -> @options = @lines[3]
    And -> @stdout = @lines[ @lines.length - 4 ]
    Then -> expect(@command).to.equal "Command: #{__dirname}/fixtures/test.js stdout"
    And -> expect(@options.trim()).to.equal 'Options: { env:'
    And -> expect(@stdout).to.equal 'Hey banana'

  context 'dynamic values', ->
    context 'cli', ->
      When -> @child = spawn 'grunt', ['simple-test:dynamic', '--no-color', '--foo=bar']
      And (done) ->
        @child.stdout.on 'data', (data) => @stdout += data.toString()
        @child.on 'close', -> done()
      And -> @stdout = @stdout.split('\n')[1]
      Then -> expect(@stdout).to.equal 'dynamic --foo bar'
      
    context 'config', ->
      When -> @child = spawn 'grunt', ['proxy', 'simple-test:dynamic-nested', '--no-color']
      And (done) ->
        @child.stdout.on 'data', (data) => @stdout += data.toString()
        @child.on 'close', -> done()
      And -> @stdout = @stdout.split('\n')[3]
      Then -> expect(@stdout).to.equal 'dynamic-nested quux --foo baz'

    context 'prompt', ->
      When -> @child = spawn 'grunt', ['simple-test:dynamic', '--no-color']
      And (done) ->
        @child.stdout.on 'data', (data) => @stdout += data.toString()
        @child.stdin.write 'quux\n'
        @child.on 'close', -> done()
      And -> @stdout = @stdout.split('\n')[3]
      Then -> expect(@stdout).to.match 'dynamic --foo quux'

  context 'custom options', ->
    When -> @child = spawn 'grunt', ['opts-test:custom', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.match 'Some foo happened! Ned was involved.'

  context 'singleDash options', ->
    When -> @child = spawn 'grunt', ['opts-test:dash', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[1]
    Then -> expect(@stdout).to.equal 'dash -foo bar'

  context 'description', ->
    When -> @child = spawn 'grunt', ['--help']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    # Grunt help output is especially annoying to parse and match against
    And -> @stdout = @stdout.split('\n').map( (line) ->
      return line.trim()
    ).join('|')
    Then -> expect(@stdout).to.match "opts-test  A simple-cli grunt wrapper for|#{__dirname}/fixtures/tes|t.js"

  context 'callback', ->
    When -> @child = spawn 'grunt', ['callback-test:cb', '--no-color']
    And (done) ->
      @child.stdout.on 'data', (data) => @stdout += data.toString()
      @child.on 'close', -> done()
    And -> @stdout = @stdout.split('\n')[4]
    Then -> expect(@stdout).to.contain 'Builder'
