describe 'simple cli', ->
  Given -> @Builder = sinon.stub()
  Given -> @Builder.returns
  Given -> @builder = spyObj 'buildOptions', 'getDynamicValues', 'spawn', 'handleCustomOption', 'debug'
  Given -> @builder.buildOptions.returns @builder
  Given -> @Builder.returns @builder
  Given -> @builder.getDynamicValues.callsArg(0)

  Given -> @cli = sandbox '../lib/simple-cli',
    './builder': @Builder

  describe 'returns a function', ->
    Then -> expect(@cli('name')).to.be.a('function')

  describe 'sets up a grunt multitask', ->
    context 'with just a string', ->
      Given -> @func = @cli 'blah'
      Given -> @grunt =
        registerMultiTask: sinon.stub()
        fail:
          fatal: sinon.stub()
      When -> @func @grunt
      Then -> expect(@grunt.registerMultiTask).to.have.been.calledWith 'blah', 'A simple-cli grunt wrapper for blah', sinon.match.func

    context 'with an object', ->
      Given -> @func = @cli
        task: 'task'
        description: 'description'
      Given -> @grunt =
        registerMultiTask: sinon.stub()
        fail:
          fatal: sinon.stub()
      When -> @func @grunt
      Then -> expect(@grunt.registerMultiTask).to.have.been.calledWith 'task', 'description', sinon.match.func
    
  describe 'configures a task', ->
    Given -> @grunt =
      registerMultiTask: sinon.stub()
      fail:
        fatal: sinon.stub()
    Given -> @cb = sinon.stub()

    context 'everything is awesome', ->
      Given -> @options =
        task: 'task'
        description: 'description'
        options:
          foo: 'bar'
        callback: @cb
      Given -> @cli(@options)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      Given -> @builder.handleCustomOption.callsArg 1
      When -> @task.apply(@context)
      Then -> expect(@Builder).to.have.been.calledWith @options, @context, @grunt
      And -> expect(@builder.buildOptions).to.have.been.called
      And -> expect(@builder.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@builder.handleCustomOption).to.have.been.calledWith 'foo', sinon.match.func
      And -> expect(@builder.spawn).to.have.been.called

    context 'async throws error', ->
      Given -> @options =
        task: 'task'
        description: 'description'
        options:
          foo: 'bar'
        callback: @cb
      Given -> @cli(@options)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      Given -> @builder.handleCustomOption.callsArgWith 1, 'error'
      When -> @task.apply(@context)
      Then -> expect(@Builder).to.have.been.calledWith @options, @context, @grunt
      And -> expect(@builder.buildOptions).to.have.been.called
      And -> expect(@builder.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@builder.handleCustomOption).to.have.been.calledWith 'foo', sinon.match.func
      And -> expect(@grunt.fail.fatal).to.have.been.calledWith 'error'
      And -> expect(@builder.spawn.called).to.be.false()

    context 'debug', ->
      Given -> @options =
        task: 'task'
        description: 'description'
        options:
          foo: 'bar'
        callback: @cb
      Given -> @builder.debugOn = true
      Given -> @cli(@options)(@grunt)
      Given -> @task = @grunt.registerMultiTask.getCall(0).args[2]
      Given -> @context = {}
      Given -> @builder.handleCustomOption.callsArgWith 1
      When -> @task.apply(@context)
      Then -> expect(@Builder).to.have.been.calledWith @options, @context, @grunt
      And -> expect(@builder.buildOptions).to.have.been.called
      And -> expect(@builder.getDynamicValues).to.have.been.calledWith sinon.match.func
      And -> expect(@builder.handleCustomOption).to.have.been.calledWith 'foo', sinon.match.func
      And -> expect(@builder.debug).to.have.been.called
      And -> expect(@builder.spawn.called).to.be.false()
