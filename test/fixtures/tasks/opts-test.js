var cli = require('../../../lib/simple-cli');
var path = require('path');

module.exports = cli({
  task: 'opts-test',
  cmd: path.resolve(__dirname, '../test.js'),
  singleDash: true,
  options: {
    foo: function(val) {
      console.log('Some foo happened!', val, 'was involved.');
    }
  }
});
