EventEmitter = require('events').EventEmitter

describe 'spawn', ->
  Given -> @grunt =
    registerMultiTask: sinon.stub()
    option: sinon.stub()
    fail:
      fatal: sinon.stub()
    log:
      writeln: sinon.stub()
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
      Given -> @cp.spawn.withArgs('foo', ['bar', '--long', 'yep', '--long-multi', 'uhuh', '--boolean']).returns @emitter
      Given -> @context.options.returns
        long: 'yep'
        longMulti: 'uhuh'
        boolean: true
        simple: {}
      When ->
        @subject.spawn @grunt, @context
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

    context 'short options', ->
      Given -> @cp.spawn.withArgs('foo', ['bar', '-cd', '-a', 'b', '-e', 'f']).returns @emitter
      Given -> @context.options.returns
        a: 'b'
        c: true
        d: true
        e: 'f'
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
    
  #describe 'command with sub-commands', ->
    #Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'remote'
    #Given -> @context.data =
      #cmd: 'remote show origin'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'command with sub-commands with the cmd at the front', ->
    #Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'remote'
    #Given -> @context.data =
      #cmd: 'git remote show origin'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'command with a different name', ->
    #Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'banana'
    #Given -> @context.data =
      #cmd: 'remote show origin'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'dasherizes commands and options', ->
    #Given -> @cp.spawn.withArgs('git', ['rev-parse', '--use-dashes'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'revParse'
    #Given -> @context.options.returns
      #useDashes: true
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'allows raw args as string', ->
    #Given -> @cp.spawn.withArgs('git', ['log', '--format=%s'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'log'
    #Given -> @context.data =
      #rawArgs: '--format=%s'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'allows raw args as array', ->
    #Given -> @cp.spawn.withArgs('git', ['log', '---blah^foo hi'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'log'
    #Given -> @context.data =
      #rawArgs: ['---blah^foo hi']
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'options have equal sign', ->
    #Given -> @cp.spawn.withArgs('git', ['log', '--author=nichols'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'log'
    #Given -> @context.options.returns
      #'author=': 'nichols'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'task is the cmd', ->
    #Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'remote'
    #Given -> @context.data = 'remote show origin'
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'array-style short option', ->
    #Given -> @cp.spawn.withArgs('git', ['commit', '-a', 'foo', '-a', 'bar'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'commit'
    #Given -> @context.options.returns
      #a: ['foo', 'bar']
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'array-style long option', ->
    #Given -> @cp.spawn.withArgs('git', ['commit', '--foo', 'bar', '--foo', 'baz'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    #Given -> @context.target = 'commit'
    #Given -> @context.options.returns
      #foo: ['bar', 'baz']
    #When ->
      #@subject.spawn @grunt, @context, 'git', @cb
      #@emitter.emit 'close', 0
    #Then -> expect(@cb).to.have.been.called

  #describe 'with dynamics values', ->
    #context 'passed via grunt.option', ->
      #Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'Blah blah blah'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
      #Given -> @context.target = 'commit'
      #Given -> @context.options.returns
        #message: '{{ message }}'
      #Given -> @grunt.option.withArgs('message').returns 'Blah blah blah'
      #When ->
        #@subject.spawn @grunt, @context, 'git', @cb
        #@emitter.emit 'close', 0
      #Then -> expect(@cb).to.have.been.called

    #context 'passed via prompt', ->
      #Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'Blah blah blah'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
      #Given -> @context.target = 'commit'
      #Given -> @context.options.returns
        #message: '{{ message }}'
      #Given -> @rl.question.withArgs('   message: ', sinon.match.func).callsArgWith(1, 'Blah blah blah')
      #When ->
        #@subject.spawn @grunt, @context, 'git', @cb
        #@emitter.emit 'close', 0
      #Then -> expect(@cb).to.have.been.called
      #And -> expect(@rl.close).to.have.been.called

    #context 'an error occurs', ->
      #Given -> @async.reduce = sinon.stub()
      #Given -> @async.reduce.callsArgWith(3, 'error', {})
      #Given -> @context.target = 'commit'
      #Given -> @context.options.returns
        #message: '{{ message }}'
      #When -> @subject.spawn @grunt, @context, 'git', @cb
      #Then -> expect(@grunt.fail.fatal).to.have.been.calledWith 'error'
