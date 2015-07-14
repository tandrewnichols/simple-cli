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
  Given -> @spawn = sinon.stub()
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
    'win-spawn': @spawn
    readline: @readline
    async: @async

  describe 'wrapped cli options', ->
    context 'no options', ->
      Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'long options', ->
      Given -> @spawn.withArgs('foo', ['bar', '--long', 'yah', '--long', 'sure', '--long-multi', 'uhuh', '--with-equal=check', '--boolean']).returns @emitter
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
      Given -> @spawn.withArgs('foo', ['bar', '-cd', '-a', 'b', '-e', 'f', '-e', 'g']).returns @emitter
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
      Given -> @spawn.withArgs('baz', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, 'baz'
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'with a different callback', ->
      Given -> @altCb = sinon.stub()
      Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, @altCb
        @emitter.emit 'close', 0
      Then -> expect(@altCb).to.have.been.calledWith 0

    context 'with a different cmd and callback', ->
      Given -> @altCb = sinon.stub()
      Given -> @spawn.withArgs('baz', ['bar']).returns @emitter
      When ->
        @subject.spawn @grunt, @context, 'baz', @altCb
        @emitter.emit 'close', 0
      Then -> expect(@altCb).to.have.been.calledWith 0
      
  describe 'simple cli opts', ->
    context 'env', ->
      Given -> @spawn.withArgs('foo', ['bar'], { env: { foo: 'bar' } }).returns @emitter
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
      Given -> @spawn.withArgs('foo', ['bar'], { cwd: 'blah' }).returns @emitter
      Given -> @context.options.returns
        simple:
          cwd: 'blah'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'force', ->
      Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
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
        Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
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
        Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
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
        Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @context.options.returns
          simple:
            cmd: 'bar'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'cmd is the different from the target', ->
        Given -> @spawn.withArgs('foo', ['blah']).returns @emitter
        Given -> @context.options.returns
          simple:
            cmd: 'blah'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

    context 'args', ->
      context 'no args', ->
        Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @context.options.returns
          simple: {}
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args is array', ->
        Given -> @spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: ['baz']
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args is string', ->
        Given -> @spawn.withArgs('foo', ['bar', 'baz', 'quux']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: 'baz quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'args with options', ->
        Given -> @spawn.withArgs('foo', ['bar', 'baz', 'quux', '--hello', 'world']).returns @emitter
        Given -> @context.options.returns
          hello: 'world'
          simple:
            args: 'baz quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

    context 'rawArgs', ->
      Given -> @spawn.withArgs('foo', ['bar', 'A commit message or other bizarre string']).returns @emitter
      Given -> @context.options.returns
        simple:
          rawArgs: 'A commit message or other bizarre string'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'task is a string', ->
      Given -> @spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
      Given -> @context.data = 'bar baz'
      Given -> @context.options.returns
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'task is an array', ->
      Given -> @spawn.withArgs('foo', ['bar', 'baz']).returns @emitter
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

      context 'with an onComplete callback', ->
        context 'debug is an object', ->
          context 'with no stderr', ->
            Given -> @complete = sinon.stub()
            Given -> @context.options.returns
              simple:
                onComplete: @complete
                debug:
                  stdout: 'foo'
            When -> @subject.spawn @grunt, @context
            Then -> expect(@complete).to.have.been.calledWith null, 'foo', @cb

          context 'with no keys', ->
            Given -> @complete = sinon.stub()
            Given -> @context.options.returns
              simple:
                onComplete: @complete
                debug: {}
            When -> @subject.spawn @grunt, @context
            Then -> expect(@complete).to.have.been.calledWith null, '[DEBUG]: stdout', @cb

          context 'with stderr', ->
            Given -> @complete = sinon.stub()
            Given -> @context.options.returns
              simple:
                onComplete: @complete
                debug:
                  stderr: 'foo'
            When -> @subject.spawn @grunt, @context
            And -> @error = @complete.getCall(0).args[0]
            Then -> expect(@complete).to.have.been.calledWith sinon.match.instanceOf(Error), '[DEBUG]: stdout', @cb
            And -> expect(@error.message).to.equal 'foo'
            And -> expect(@error.code).to.equal 1

        context 'debug is not an object', ->
          Given -> @complete = sinon.stub()
          Given -> @context.options.returns
            simple:
              onComplete: @complete
              debug: true
          When -> @subject.spawn @grunt, @context
          And -> @error = @complete.getCall(0).args[0]
          Then -> expect(@complete).to.have.been.calledWith sinon.match.instanceOf(Error), '[DEBUG]: stdout', @cb
          And -> expect(@error.message).to.equal '[DEBUG]: stderr'
          And -> expect(@error.code).to.equal 1

      context 'triggered via grunt.option', ->
        Given -> @grunt.option.withArgs('debug').returns true
        Given -> @context.options.returns
          simple: {}
        When -> @subject.spawn @grunt, @context
        Then -> expect(@grunt.log.writeln).to.have.been.calledWith 'Command: ' + chalk.cyan('foo bar')
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'Options: ' + chalk.cyan(util.inspect({ env: undefined, cwd: undefined}))

    context 'custom options', ->
      context 'no options provided by end-user', ->
        Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
        Given -> @context.options.returns
          simple: {}
        Given -> @banana = sinon.stub()
        When ->
          @subject.spawn @grunt, @context, { banana: @banana }
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0
        And -> expect(@banana.called).to.be.false()

      context 'custom option provided', ->
        context 'everything is awesome', ->
          Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
          Given -> @context.options.returns
            simple:
              banana: 'a yellow fruit'
          Given -> @banana = sinon.stub()
          Given -> @banana.callsArg(2)
          When ->
            @subject.spawn @grunt, @context, { banana: @banana }
            @emitter.emit 'close', 0
          Then -> expect(@cb).to.have.been.calledWith 0
          And -> expect(@banana).to.have.been.calledWith 'a yellow fruit',
            cmd: 'foo'
            target: 'bar'
            args: []
            rawArgs: undefined
            options: {}
          , sinon.match.func

        context 'an error', ->
          Given -> @spawn.withArgs('foo', ['bar']).returns @emitter
          Given -> @context.options.returns
            simple:
              banana: 'a yellow fruit'
          Given -> @banana = sinon.stub()
          Given -> @banana.callsArgWith(2, 'error')
          When ->
            @subject.spawn @grunt, @context, { banana: @banana }
            @emitter.emit 'close', 0
          Then -> expect(@banana).to.have.been.calledWith 'a yellow fruit',
            cmd: 'foo'
            target: 'bar'
            args: []
            rawArgs: undefined
            options: {}
          , sinon.match.func
          And -> expect(@grunt.fail.fatal).to.have.been.calledWith 'error'

        context 'options modified', ->
          Given -> @spawn.withArgs('foo', ['blah', '--fooberry']).returns @emitter
          Given -> @context.options.returns
            foo: true
            simple:
              banana: 'a yellow fruit'
          Given -> @banana = (val, context, next) ->
            context.target = 'blah'
            context.args[0] += 'berry'
            next()
          When ->
            @subject.spawn @grunt, @context, { banana: @banana }
            @emitter.emit 'close', 0
          Then -> expect(@cb).to.have.been.calledWith 0

  describe 'with dynamics values', ->
    context 'passed via grunt.option', ->
      Given -> @spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
      Given -> @context.options.returns
        greeting: '{{ greeting }}'
        simple: {}
      Given -> @grunt.option.withArgs('greeting').returns 'Hello world'
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'passed via grunt.option in args', ->
      context 'as array', ->
        Given -> @spawn.withArgs('foo', ['bar', 'quux']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: ['{{ baz }}']
        Given -> @grunt.option.withArgs('baz').returns 'quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

      context 'as string', ->
        Given -> @spawn.withArgs('foo', ['bar', 'quux', 'blah']).returns @emitter
        Given -> @context.options.returns
          simple:
            args: '{{baz}} blah'
        Given -> @grunt.option.withArgs('baz').returns 'quux'
        When ->
          @subject.spawn @grunt, @context
          @emitter.emit 'close', 0
        Then -> expect(@cb).to.have.been.calledWith 0

    context 'passed via grunt.config', ->
      Given -> @spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
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
        Given -> @spawn.withArgs('foo', ['bar', '--greeting', 'Hello world']).returns @emitter
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
