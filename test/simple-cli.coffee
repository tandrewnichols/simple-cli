EventEmitter = require('events').EventEmitter

describe 'spawn', ->
  Given -> @grunt =
    registerMultiTask: sinon.stub()
    log:
      writeln: sinon.stub()
  Given -> @context =
    async: sinon.stub()
    options: sinon.stub()
    data: {}
  Given -> @cb = sinon.stub()
  Given -> @context.async.returns @cb
  Given -> @context.options.returns {}
  Given -> @cp =
    spawn: sinon.stub()
  Given -> @emitter = new EventEmitter()
  Given -> @cwd = process.cwd()
  Given -> @subject = sandbox '../lib',
    child_process: @cp

  describe 'command with options', ->
    Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'A commit message'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'commit'
    Given -> @context.options.returns
      message: 'A commit message'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'command with a boolean flag', ->
    Given -> @cp.spawn.withArgs('git', ['status', '--short'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'status'
    Given -> @context.options.returns
      short: true
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'command with short flags', ->
    Given -> @cp.spawn.withArgs('git', ['status', '-ac', '-b', 'foo', '-d', 'bar'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'status'
    Given -> @context.options.returns
      a: true
      b: 'foo'
      c: true
      d: 'bar'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'command with extra options', ->
    describe 'stdio is not false', ->
      Given -> @emitter.stdout = new EventEmitter()
      Given -> @emitter.stderr = new EventEmitter()
      Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'A commit message'], { stdio: 'foo', cwd: 'bar' }).returns @emitter
      Given -> @context.target = 'commit'
      Given -> @context.options.returns
        message: 'A commit message'
        cwd: 'bar'
        stdio: 'foo'
      When ->
        @subject.spawn @grunt, @context, 'git', @cb
        @emitter.stdout.emit 'data', 'stdout'
        @emitter.stderr.emit 'data', 'stderr'
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0
      And -> expect(@grunt.log.writeln).to.have.been.calledWith 'stdout'
      And -> expect(@grunt.log.writeln).to.have.been.calledWith 'stderr'

    describe 'an error is thrown', ->
      describe 'force is true', ->
        Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'A commit message'], { stdio: 'inherit', cwd: 'bar' }).returns @emitter
        Given -> @context.target = 'commit'
        Given -> @context.options.returns
          message: 'A commit message'
          cwd: 'bar'
          force: true
        When ->
          @subject.spawn @grunt, @context, 'git', @cb
          @emitter.emit 'close', 2
        Then -> expect(@cb).to.have.been.calledWith 0
        And -> expect(@grunt.log.writeln).to.have.been.calledWith 'git:commit returned code 2. Ignoring...'

      describe 'force is false', ->
        Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'A commit message'], { stdio: 'inherit', cwd: 'bar' }).returns @emitter
        Given -> @context.target = 'commit'
        Given -> @context.options.returns
          message: 'A commit message'
          cwd: 'bar'
        When ->
          @subject.spawn @grunt, @context, 'git', @cb
          @emitter.emit 'close', 2
        Then -> expect(@cb).to.have.been.calledWith 2

    describe 'stdio is false', ->
      Given -> @cp.spawn.withArgs('git', ['commit', '--message', 'A commit message'], { cwd: 'bar' }).returns @emitter
      Given -> @context.target = 'commit'
      Given -> @context.options.returns
        message: 'A commit message'
        cwd: 'bar'
        stdio: false
      When ->
        @subject.spawn @grunt, @context, 'git', @cb
        @emitter.emit 'close', 0
      Then -> expect(@cb).to.have.been.calledWith 0

  describe 'command with sub-commands', ->
    Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'remote'
    Given -> @context.data =
      cmd: 'remote show origin'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'command with sub-commands with the cmd at the front', ->
    Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'remote'
    Given -> @context.data =
      cmd: 'git remote show origin'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'command with a different name', ->
    Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'banana'
    Given -> @context.data =
      cmd: 'remote show origin'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'dasherizes commands and options', ->
    Given -> @cp.spawn.withArgs('git', ['rev-parse', '--use-dashes'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'revParse'
    Given -> @context.options.returns
      useDashes: true
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'allows raw args as string', ->
    Given -> @cp.spawn.withArgs('git', ['log', '--format=%s'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'log'
    Given -> @context.data =
      rawArgs: '--format=%s'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'allows raw args as array', ->
    Given -> @cp.spawn.withArgs('git', ['log', '---blah^foo hi'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'log'
    Given -> @context.data =
      rawArgs: ['---blah^foo hi']
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'options have equal sign', ->
    Given -> @cp.spawn.withArgs('git', ['log', '--author=nichols'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'log'
    Given -> @context.options.returns
      'author=': 'nichols'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called

  describe 'task is the cmd', ->
    Given -> @cp.spawn.withArgs('git', ['remote', 'show', 'origin'], { stdio: 'inherit', cwd: @cwd }).returns @emitter
    Given -> @context.target = 'remote'
    Given -> @context.data = 'remote show origin'
    When ->
      @subject.spawn @grunt, @context, 'git', @cb
      @emitter.emit 'close', 0
    Then -> expect(@cb).to.have.been.called
