chalk = require 'chalk'
util = require 'util'

describe 'builder', ->
  Given -> @async = {}
  Given -> @spawn = sinon.stub()
  Given -> @readline =
    createInterface: sinon.stub()
  Given -> @Builder = sandbox '../lib/builder',
    'win-spawn': @spawn
    readline: @readline
    async: @async

  describe 'constructor', ->
    Given -> @options =
      cmd: 'cmd'
      task: 'task'
      callback:
        bind: sinon.stub()
      options: 'options'
    Given -> @options.callback.bind.returns 'bound'
    Given -> @context =
      options: sinon.stub()
      async: sinon.stub()
    Given -> @grunt =
      option: sinon.stub()
    Given -> @context.options.returns
      simple:
        debug: true
        env:
          HELLO: 'world'
      foo: 'bar'
    Given -> @context.async.returns 'async'

    context 'options.cmd', ->
      Given -> @env = process.env
      Given -> @env.HELLO = 'world'
      # For some reason, asserting that @builder.env is deep equal to @env fails,
      # but ONLY on iojs. Stringifying and parsing both makes it pass. Alas.
      Given -> @env = JSON.parse(JSON.stringify(@env))
      When -> @builder = new @Builder @options, @context, @grunt
      And -> @builderEnv = JSON.parse(JSON.stringify(@builder.env))
      Then -> expect(@builder.cmd).to.equal 'cmd'
      And -> expect(@builder.callback).to.equal 'bound'
      And -> expect(@builder.done).to.equal 'async'
      And -> expect(@builder.options).to.deep.equal foo: 'bar'
      And -> expect(@builder.config).to.deep.equal
        debug: true
        env:
          HELLO: 'world'
      And -> expect(@builder.debugOn).to.be.true()
      And -> expect(@builder.context).to.equal @context
      And -> expect(@builder.grunt).to.equal @grunt
      And -> expect(@builder.customOptions).to.equal 'options'
      And -> expect(@builderEnv).to.deep.equal @env

    context 'options.task', ->
      Given -> delete @options.cmd
      When -> @builder = new @Builder @options, @context, @grunt
      Then -> expect(@builder.cmd).to.equal 'task'

    context 'no callback', ->
      Given -> delete @options.callback
      When -> @builder = new @Builder @options, @context, @grunt
      Then -> expect(@builder.done).to.equal 'async'
      Then -> expect(@builder.callback).to.equal 'async'

    context 'grunt.option', ->
      Given -> @grunt.option.withArgs('debug').returns 'grunt'
      When -> @builder = new @Builder @options, @context, @grunt
      Then -> expect(@builder.debugOn).to.equal 'grunt'

  describe '.configure', ->
    Given -> @context =
      context:
        target: 'bananaStand'
        data: {}
      config:
        cmd: 'foo'

    context 'cmd', ->
      When -> @builder = @Builder.prototype.configure.apply @context
      Then -> expect(@context.target).to.equal 'foo'
      And -> expect(@builder).to.equal @context

    context 'context.target', ->
      Given -> delete @context.config.cmd
      When -> @builder = @Builder.prototype.configure.apply @context
      Then -> expect(@context.target).to.equal 'banana-stand'

    context 'data is string', ->
      Given -> @context.context.data = 'git er done'
      When -> @builder = @Builder.prototype.configure.apply @context
      Then -> expect(@context.target).to.equal 'git'
      And -> expect(@context.config.cmd).to.equal 'git'
      And -> expect(@context.config.args).to.deep.equal ['er', 'done']

    context 'data is array', ->
      Given -> @context.context.data = ['git', 'er', 'done']
      When -> @builder = @Builder.prototype.configure.apply @context
      Then -> expect(@context.target).to.equal 'git'
      And -> expect(@context.config.cmd).to.equal 'git'
      And -> expect(@context.config.args).to.deep.equal ['er', 'done']

    context 'args is string', ->
      Given -> @context.config.args = 'git er done'
      When -> @builder = @Builder.prototype.configure.apply @context
      Then -> expect(@context.target).to.equal 'foo'
      And -> expect(@context.config.cmd).to.equal 'foo'
      And -> expect(@context.config.args).to.deep.equal ['git', 'er', 'done']

  describe '.buildOptions', ->
    context 'with no singleDash', ->
      Given -> @context =
        config:
          args: ['foo', 'bar']
          rawArgs: ['hello', 'world']
        options:
          a: true
          b: 'b'
          bool: true
          long: 'baz'
          'name=': 'Andrew'
          list: ['rope', 'jelly']
      When -> @Builder.prototype.buildOptions.apply @context
      Then -> expect(@context.args).to.deep.equal [
        'foo', 'bar',
        '-a', '-b', 'b',
        '--bool', '--long', 'baz',
        '--name=Andrew',
        '--list', 'rope',
        '--list', 'jelly',
        'hello', 'world'
      ]

    context 'with singleDash', ->
      Given -> @context =
        singleDash: true
        config:
          args: ['foo', 'bar']
          rawArgs: ['hello', 'world']
        options:
          a: true
          b: 'b'
          bool: true
          long: 'baz'
          'name=': 'Andrew'
          list: ['rope', 'jelly']
      When -> @Builder.prototype.buildOptions.apply @context
      Then -> expect(@context.args).to.deep.equal [
        'foo', 'bar',
        '-a', '-b', 'b',
        '-bool', '-long', 'baz',
        '-name=Andrew',
        '-list', 'rope',
        '-list', 'jelly',
        'hello', 'world'
      ]

  describe '.getDynamicValues', ->
    Given -> @cb = sinon.stub()
    Given -> @context =
      populateFromGrunt: sinon.stub()
      template: sinon.stub()
      getReadlineValues: sinon.stub()

    context 'no keys', ->
      Given -> @context.args = ['a', 'b']
      When -> @Builder.prototype.getDynamicValues.call @context, @cb
      Then -> expect(@cb).to.have.been.called
      And -> expect(@context.populateFromGrunt.called).to.be.false()

    context 'all keys filled by grunt', ->
      Given -> @context.args = ['{{ a }}', '{{ b }}']
      Given -> @context.populateFromGrunt.returns a: 'b', b: 'c'
      When -> @Builder.prototype.getDynamicValues.call @context, @cb
      Then -> expect(@context.populateFromGrunt).to.have.been.calledWith ['a', 'b']
      And -> expect(@context.template).to.have.been.calledWith '{{ a }}||{{ b }}',
        a: 'b'
        b: 'c'
      And -> expect(@cb).to.have.been.called

    context 'some keys missing', ->
      Given -> @context.args = ['{{ a }}', '{{ b }}']
      Given -> @context.populateFromGrunt.returns a: 'b', b: null
      When -> @Builder.prototype.getDynamicValues.call @context, @cb
      Then -> expect(@context.populateFromGrunt).to.have.been.calledWith ['a', 'b']
      And -> expect(@context.template.called).to.be.false()
      And -> expect(@context.getReadlineValues).to.have.been.calledWith ['b'], { a: 'b', b: null }, '{{ a }}||{{ b }}', @cb


  describe '.getReadlineValues', ->
    # There are ridiculous shenanigans involved in
    # stubbing console.log only SOMETIMES. But . . .
    # I really hate noise in test output, so
    # I'm doing it anyway.
    ###### Commense shenanigans #######
    afterEach -> console.log.restore()
    Given -> @log = console.log # Store a reference to log, so we can stub it but still call it
    Given -> @console = console # Need a reference to console, so we can apply it later
    # The rarely used 3-arg versoin of .stub, where the 3rd argument is the function
    # to call when the stub is invoked
    Given -> sinon.stub console, 'log', (a) =>
      # If this a log generated by the test itself, ignore it.
      # If it's generated by the test framework . . . these aren't thre droids we're looking for.
      if a and a.indexOf('Enter values for') == -1
        @log.apply @console, arguments
    ###### End shenanigans #######
    
    Given -> @cb = sinon.stub()
    Given -> @context =
      populateFromGrunt: sinon.stub()
      template: sinon.stub()
      prompt: sinon.stub()
      args: ['{{ a }}', '{{ b }}']
      grunt:
        fail:
          fatal: sinon.stub()
    Given -> @rl =
      close: sinon.stub()
    Given -> @readline.createInterface.withArgs(
      input: process.stdin
      output: process.stdout
    ).returns @rl

    context 'async no error', ->
      Given -> @context.prompt.callsArgWith 1, 'answer'
      Given -> @context.populateFromGrunt.returns a: 'b', b: null
      When -> @Builder.prototype.getReadlineValues.call @context, ['b'], { a: 'b', b: null }, '{{ a }}||{{ b }}', @cb
      Then -> expect(@context.prompt).to.have.been.calledWith 'b', sinon.match.func
      And -> expect(@rl.close).to.have.been.called
      And -> expect(@context.template).to.have.been.calledWith '{{ a }}||{{ b }}',
        a: 'b',
        b: 'answer'
      And -> expect(@cb).to.have.been.called

    context 'async error', ->
      afterEach -> @async.reduce.restore()
      Given -> sinon.stub @async, 'reduce'
      Given -> @async.reduce.callsArgWith 3, 'error'
      When -> @Builder.prototype.getReadlineValues.call @context, ['b'], { a: 'b', b: null }, '{{ a }}||{{ b }}', @cb
      Then -> expect(@rl.close).to.have.been.called
      And -> expect(@context.grunt.fail.fatal).to.have.been.calledWith 'error'

  describe '.populateFromGrunt', ->
    Given -> @context =
      grunt:
        option: sinon.stub()
        config:
          get: sinon.stub()
    Given -> @context.grunt.option.withArgs('foo').returns 'banana'
    Given -> @context.grunt.config.get.withArgs('bar').returns 'kiwi'
    When -> @obj = @Builder.prototype.populateFromGrunt.call @context, ['foo', 'bar', 'baz']
    Then -> expect(@obj).to.deep.equal
      foo: 'banana'
      bar: 'kiwi'
      baz: null

  describe '.template', ->
    Given -> @context = {}
    When -> @Builder.prototype.template.call @context, '{{ foo }}||{{ bar }}', { foo: 'banana', bar: 'cream pie' }
    Then -> expect(@context.args).to.deep.equal ['banana', 'cream pie']
    
  describe '.prompt', ->
    Given -> @context =
      rl:
        question: sinon.stub()
    When -> @Builder.prototype.prompt.call @context, 'blah', 'cb'
    Then -> expect(@context.rl.question).to.have.been.calledWith '   blah: ', 'cb'

  describe '.handleCustomOption', ->
    context 'with option', ->
      Given -> @context =
        config:
          foo: 'bar'
        customOptions:
          foo: sinon.stub()
      Given -> @cb = sinon.stub()
      When -> @Builder.prototype.handleCustomOption.call @context, 'foo', @cb
      Then -> expect(@context.customOptions.foo).to.have.been.calledWith 'bar', @cb
      And -> expect(@context.customOptions.foo).to.have.been.calledOn @context

    context 'with no option', ->
      Given -> @context =
        config: {}
        customOptions:
          foo: sinon.stub()
      Given -> @cb = sinon.stub()
      When -> @Builder.prototype.handleCustomOption.call @context, 'foo', @cb
      Then -> expect(@cb).to.have.been.called

  describe '.debug', ->
    Given -> @context =
      callComplete: sinon.stub()
      grunt:
        log:
          writeln: sinon.stub()
      config:
        cwd: 'cwd'
        onComplete: true
        debug:
          stdout: 'stdout'
          stderr: 'stderr'
      cmd: 'cmd'
      target: 'target'
      args: ['foo', 'bar']
      env: 'env'
      callback: sinon.stub()

    context 'with onComplete', ->
      context 'debug is object', ->
        When -> @Builder.prototype.debug.call @context
        Then -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('cmd target foo bar')
        And -> expect(@context.grunt.log.writeln).to.have.been.calledWith()
        And -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect(
          env: 'env'
          cwd: 'cwd'
        ))
        And -> expect(@context.callComplete).to.have.been.calledWith 1, 'stderr', 'stdout'

      context 'debug is boolean', ->
        Given -> @context.config.debug = true
        When -> @Builder.prototype.debug.call @context
        Then -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('cmd target foo bar')
        And -> expect(@context.grunt.log.writeln).to.have.been.calledWith()
        And -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect(
          env: 'env'
          cwd: 'cwd'
        ))
        And -> expect(@context.callComplete).to.have.been.calledWith 1, '[DEBUG]: stderr', '[DEBUG]: stdout'

    context 'with no onComplete', ->
      Given -> delete @context.config.onComplete
      When -> @Builder.prototype.debug.call @context
      Then -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('cmd target foo bar')
      And -> expect(@context.grunt.log.writeln).to.have.been.calledWith()
      And -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect(
        env: 'env'
        cwd: 'cwd'
      ))
      And -> expect(@context.callback).to.have.been.called

  describe '.callComplete', ->
    Given -> @context =
      callback: 'done'
      config:
        onComplete: sinon.stub()

    context 'with a code', ->
      When -> @Builder.prototype.callComplete.call @context, 1, 'err', 'out'
      Then -> expect(@context.config.onComplete).to.have.been.calledWith sinon.match({ message: 'err', code: 1 }), 'out', 'done'

    context 'with no code but stderr', ->
      When -> @Builder.prototype.callComplete.call @context, null, 'err', 'out'
      Then -> expect(@context.config.onComplete).to.have.been.calledWith sinon.match({ message: 'err', code: null }), 'out', 'done'

    context 'no error', ->
      When -> @Builder.prototype.callComplete.call @context, null, null, 'out'
      Then -> expect(@context.config.onComplete).to.have.been.calledWith null, 'out', 'done'

  describe '.spawn', ->
    Given -> @child =
      stdout:
        on: sinon.stub()
      stderr:
        on: sinon.stub()
      on: sinon.stub()
    Given -> @spawn.withArgs('cmd', ['target', 'foo', 'bar'], { env: 'env', cwd: 'cwd' }).returns @child
    Given -> @context =
      callComplete: sinon.stub()
      callback: sinon.stub()
      cmd: 'cmd'
      target: 'target'
      args: ['foo', 'bar']
      env: 'env'
      config:
        cwd: 'cwd'
        onComplete: true
      grunt:
        log:
          writeln: sinon.stub()
    When -> @Builder.prototype.spawn.call @context
    And -> @child.stdout.on.getCall(0).args[1] 'data'
    And -> @child.stderr.on.getCall(0).args[1] 'error'
    And -> @close = @child.on.getCall(0).args[1]

    context 'no failure', ->
      context 'with onComplete', ->
        When -> @close()
        Then -> expect(@context.callComplete).to.have.been.calledWith undefined, 'error', 'data'
        And -> expect(@context.grunt.log.writeln.called).to.be.false()

      context 'with no onComplete', ->
        When -> delete @context.config.onComplete
        And -> @close()
        Then -> expect(@context.callback).to.have.been.calledWith undefined
        And -> expect(@context.grunt.log.writeln.called).to.be.false()

    context 'with failure but no force', ->
      context 'with onComplete', ->
        When -> @close(1)
        Then -> expect(@context.callComplete).to.have.been.calledWith 1, 'error', 'data'
        And -> expect(@context.grunt.log.writeln.called).to.be.false()

      context 'with no onComplete', ->
        When -> delete @context.config.onComplete
        And -> @close(1)
        Then -> expect(@context.callback).to.have.been.calledWith 1
        And -> expect(@context.grunt.log.writeln.called).to.be.false()

    context 'with failure and force', ->
      When -> @context.config.force = true

      context 'with onComplete', ->
        When -> @close(1)
        Then -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'cmd:target returned code 1. Ignoring...'
        And -> expect(@context.callComplete).to.have.been.calledWith 0, 'error', 'data'

      context 'with no onComplete', ->
        When -> delete @context.config.onComplete
        And -> @close(1)
        Then -> expect(@context.grunt.log.writeln).to.have.been.calledWith 'cmd:target returned code 1. Ignoring...'
        And -> expect(@context.callback).to.have.been.calledWith 0
