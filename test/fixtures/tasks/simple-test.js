var cli = require('../../../lib/simple-cli');
var path = require('path');

module.exports = cli({
  task: 'simple-test',
  description: 'Test',
  cmd: path.resolve(__dirname, '../test.js')
});
