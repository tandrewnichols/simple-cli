describe 'lodash', ->
  Given -> @lodash = require '../lib/lodash'

  context 'adds underscore.string methods', ->
    Then -> expect(@lodash.startsWith('foo', 'f')).to.be.true()

  context 'has the right interpolation settings', ->
    When -> @template = @lodash.template('{{ foo }}')({ foo: 'banana' })
    Then -> expect(@template).to.equal 'banana'

  context 'is an isolated instance of lodash', ->
    Then -> expect(@lodash).not.to.equal require('lodash')
