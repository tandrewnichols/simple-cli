EventEmitter = require('events').EventEmitter
chalk = require('chalk')
util = require('util')

describe 'spawn', ->
  Given -> @grunt =
    registerMultiTask: sinon.stub()
    option: sinon.stub()
    fail:
      fatal: sinon.stub()
    log:
      writeln: sinon.stub()
    config:
      get: sinon.stub()
  Given -> @context =
    name: 'foo'
    target: 'bar'
    async: sinon.stub()
    options: sinon.stub()
    data: {}
  Given -> @cb = sinon.stub()
  Given -> @context.async.returns @cb
  Given -> @context.options.returns { simple: {} }
  Given -> @cp =
    spawn: sinon.stub()
  Given -> @readline =
    createInterface: sinon.stub()
    '@global': true
  Given -> @rl =
    question: sinon.stub()
    close: sinon.stub()
  Given -> @readline.createInterface.returns @rl
  Given -> @async =
    '@global': true
  Given -> @emitter = new EventEmitter()
  Given -> @subject = sandbox '../lib',
    child_process: @cp
    readline: @readline
    async: @async

  describe 'wrapped cli options', ->
    context 'no options', ->
      Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'long options', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', '--long', 'yah', '--long', 'sure', '--long-multi', 'uhuh', '--with-equal=check', '--boolean']).returns @emitter
      Given -> @context.options.returns
        long: ['yah', 'sure']
        longMulti: 'uhuh'
        'withEqual=': 'check'
        boolean: true
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'short options', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', '-cd', '-a', 'b', '-e', 'f', '-e', 'g']).returns @emitter
      Given -> @context.options.returns
        a: 'b'
        c: true
        d: true
        e: ['f', 'g']
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

  describe 'simple cli invoked differently', ->
    context 'with an alternate cmd', ->
      Given -> @cp.spawn.withArgs('baz', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, 'baz'
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'with a different callback', ->
      Given -> @altCb = sinon.stub()
      Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, @altCb
        @emitter.emit 'close', 0
      Then -> expect(@altCb).to.have.been.calledWith 0

    context 'with a different cmd and callback', ->
      Given -> @altCb = sinon.stub()
      Given -> @cp.spawn.withArgs('baz', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, 'baz', @altCb
        @emitter.emit 'close', 0
      Then -> expect(@altCb).to.have.been.calledWith 0
      
  describe 'simple cli opts', ->
    context 'env', ->
      Given -> @cp.spawn.withArgs('foo', ['bar'], { env: { foo: 'bar' } }).returns @emitter
      Given -> @env = process.env
      Given -> process.env = {}
      afterEach -> process.env = @env
      Given -> @context.options.returns
        simple:
          env:
            foo: 'bar'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'cwd', ->
      Given -> @cp.spawn.withArgs('foo', ['bar'], { cwd: 'blah' }).returns @emitter
      Given -> @context.options.returns
        simple:
          cwd: 'blah'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'force', ->
      Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
      Given -> @context.options.returns
        simple:
          force: true
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 1
      Then -> expect(@cb).to.have.been.calledWith 0
      And -> expect(@grunt.log.writeln).to.have.been.calledWith 'foo:bar returned code 1. Ignoring...'

    context 'onComplete', ->
      Given -> @emitter.stdout = new EventEmitter()
      Given -> @emitter.stderr = new EventEmitter()
      context 'success', ->
        Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @complete = sinon.stub()
        Given -> @context.options.returns
          simple:
            onComplete: @complete
        When ->
          @subject.spawn @grunt, @context
          @emitter.stdout.emit 'data', new Buffer('stdout')
          @emitter.emit 'close', 0
        Then -> expect(@complete).to.have.been.calledWith null, 'stdout', @cb

      context 'failure', ->
        Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @complete = sinon.stub()
        Given -> @context.options.returns
          simple:
            onComplete: @complete
        When ->
          @subject.spawn @grunt, @context
          @emitter.stderr.emit 'data', new Buffer('stderr')
          @emitter.emit 'close', 1
        And -> @error = @complete.getCall(0).args[0]
        Then -> expect(@complete).to.have.been.calledWith sinon.match.instanceOf(Error), '', @cb
        And -> expect(@error.message).to.equal 'stderr'
        And -> expect(@error.code).to.equal 1

    context 'cmd', ->
      context 'cmd is the same as the target', ->
        Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @context.options.returns
          simple:
            cmd: 'bar'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'cmd is the different from the target', ->
        Given -> @cp.spawn.withArgs('foo', ['blah']).returns @emitter
        Given -> @context.options.returns
          simple:
            cmd: 'blah'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

    context 'args', ->
      context 'no args', ->
        Given -> @cp.spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @context.options.returns
          simple: {}
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args is array', ->
        Given -> @cp.spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: ['baz']
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args is string', ->
        Given -> @cp.spawn.withArgs('foo', ['bar', 'baz', 'quux']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: 'baz quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args with options', ->
        Given -> @cp.spawn.withArgs('foo', ['bar', 'baz', 'quux', '--hello', 'world']).returns @emitter
        Given -> @context.options.returns
          hello: 'world'
          simple:
            args: 'baz quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

    context 'rawArgs', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', 'A commit message or other bizarre string']).returns @emitter
      Given -> @context.options.returns
        simple:
          rawArgs: 'A commit message or other bizarre string'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'task is a string', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
      Given -> @context.data = 'bar baz'
      Given -> @context.options.returns
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'task is an array', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
      Given -> @context.data = ['bar', 'baz']
      Given -> @context.options.returns
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'debug', ->
      context 'no options', ->
        Given -> @context.options.returns
          simple:
            debug: true
        When ->
          @subject.spawn @grunt, @context
        Then -> expect(@cb).to.have.been.calledWith()
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('foo bar')
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect({ env: undefined, cwd: undefined}))

      context 'with options', ->
        Given -> @context.options.returns
          simple:
            debug: true
            cwd: 'foo'
            env:
              hello: 'world'
        When ->
          @subject.spawn @grunt, @context
        Then -> expect(@cb).to.have.been.calledWith()
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('foo bar')
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect({ env: { hello: 'world' }, cwd: 'foo'}))

    context 'dryRun', ->
      context 'no options', ->
        Given -> @context.options.returns
          simple:
            dryRun: true
        When ->
          @subject.spawn @grunt, @context
        Then -> expect(@cb).to.have.been.calledWith()
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('foo bar')
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect({ env: undefined, cwd: undefined}))

      context 'with options', ->
        Given -> @context.options.returns
          simple:
            dryRun: true
            cwd: 'foo'
            env:
              hello: 'world'
        When ->
          @subject.spawn @grunt, @context
        Then -> expect(@cb).to.have.been.calledWith()
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('foo bar')
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect({ env: { hello: 'world' }, cwd: 'foo'}))

  describe 'with dynamics values', ->
    context 'passed via grunt.option', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
      Given -> @context.options.returns
        greeting: '{{ greeting }}'
        simple: {}
      Given -> @grunt.option.withArgs('greeting').returns 'Hello world'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'passed via grunt.config', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
      Given -> @context.options.returns
        greeting: '{{ greeting }}'
        simple: {}
      Given -> @grunt.config.get.withArgs('greeting').returns 'Hello world'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'passed via prompt', ->
      context 'everything is awesome', ->
        Given -> @cp.spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
        Given -> @context.options.returns
          greeting: '{{ greeting }}'
          simple: {}
        Given -> @rl.question.withArgs('   greeting: ', sinon.match.func).callsArgWith(1, 'Hello world')
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0
        And -> expect(@rl.close).to.have.been.called

      context 'an error occurs', ->
        Given -> @async.reduce = sinon.stub()
        Given -> @async.reduce.callsArgWith(3, 'error', {})
        Given -> @context.options.returns
          greeting: '{{ greeting }}'
          simple: {}
        When -> @subject.spawn @grunt, @context
        Then -> expect(@grunt.fail.fatal).to.have.been.calledWith 'error'
