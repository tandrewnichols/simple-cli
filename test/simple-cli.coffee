_cmd = null
_done = null
_context = null
_grunt = null
_customOpts = null

describe 'simple cli', ->
  Given -> @Builder = class Builder
    constructor: (@cmd, @done, @context, @grunt, @customOpts) ->
      _cmd = @cmd
      _done = @done
      _context = @context
      _grunt = @grunt
      _customOpts = @customOpts
    configure: -> return this
    buildOptions: -> return this
    getDynamicValues: (cb) -> cb()
    spawn: sinon.stub()

  Given -> sinon.spy @Builder.prototype, 'configure'
  Given -> sinon.spy @Builder.prototype, 'buildOptions'
  Given -> sinon.spy @Builder.prototype, 'getDynamicValues'

  Given -> @cli = sandbox '../lib/simple-cli',
    async: {}
    './builder': @Builder

  describe 'returns a function', ->
    Then -> expect(@cli.spawn('name', 'description')).to.be.a('function')

  describe 'sets up a grunt multitask', ->
    Given -> @func = @cli.spawn('name', 'description')
    Given -> @grunt =
      registerMultiTask: sinon.stub()
      fail:
        fatal: sinon.stub()
    When -> @func @grunt
    Then -> expect(@grunt.registerMultiTask).to.have.been.calledWith 'name', 'description', sinon.match.func
    
  describe 'configures a task', ->
    Given -> @grunt =
      registerMultiTask: sinon.stub()
    Given -> @cb = sinon.stub()

    context 'where the task name is the binary name', ->
      Given -> @opts = {}
      Given -> @cli.spawn('taskname', 'description', @opts, @cb)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      When -> @task.apply(@context)
      Then -> expect(@Builder.prototype.configure).to.have.been.called
      And -> expect(@Builder.prototype.buildOptions).to.have.been.called
      And -> expect(@Builder.prototype.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@Builder.prototype.spawn).to.have.been.called
      And -> expect(_cmd).to.equal 'taskname'
      And -> expect(_done).to.equal @cb
      And -> expect(_context).to.equal @context
      And -> expect(_grunt).to.equal @grunt
      And -> expect(_customOpts).to.equal @opts

    context 'where the binary name is different from the task name', ->
      Given -> @opts = {}
      Given -> @cli.spawn('taskname', 'description', @opts, 'binary', @cb)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      When -> @task.apply(@context)
      Then -> expect(@Builder.prototype.configure).to.have.been.called
      And -> expect(@Builder.prototype.buildOptions).to.have.been.called
      And -> expect(@Builder.prototype.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@Builder.prototype.spawn).to.have.been.called
      And -> expect(_cmd).to.equal 'binary'
      And -> expect(_done).to.equal @cb
      And -> expect(_context).to.equal @context
      And -> expect(_grunt).to.equal @grunt
      And -> expect(_customOpts).to.equal @opts

    context 'where getDynamicValues throws an error', ->
      Given -> @opts = {}
      Given -> @cli.spawn('taskname', 'description', @opts, 'binary', @cb)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      When -> @task.apply(@context)
      Then -> expect(@Builder.prototype.configure).to.have.been.called
      And -> expect(@Builder.prototype.buildOptions).to.have.been.called
      And -> expect(@Builder.prototype.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@Builder.prototype.spawn).to.have.been.called
      And -> expect(_cmd).to.equal 'binary'
      And -> expect(_done).to.equal @cb
      And -> expect(_context).to.equal @context
      And -> expect(_grunt).to.equal @grunt
      And -> expect(_customOpts).to.equal @opts
