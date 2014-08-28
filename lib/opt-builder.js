var _ = require('lodash');

exports.build = function(options) {
  var flag = [];
  var nonFlag = [];

  // Handle long opts
  var cmdOpts = _(options).omit('cwd', 'stdio', 'force').keys().reduce(function(memo, key) {
    // Allow short options
    if (key.length === 1) {
      if (options[key] === true) {
        flag.push(key);
      } else {
        nonFlag.push(key);
      }
    } else {
      if (_.endsWith(key, '=')) {
        memo.push('--' + _.dasherize(key) + options[key]);
      } else {
        memo.push('--' + _.dasherize(key));
        // Specifically allow "true" to mean "this flag has no arg with it"
        if (options[key] !== true) {
          memo.push(options[key]);
        }
      }
    }
    return memo;
  }, []);

  // Collect short opt flags into one item (e.g. -abc)
  if (flag.length) {
    cmdOpts.push('-' + flag.join(''));
  }

  // Add short opts with values
  _.each(nonFlag, function(k) {
    cmdOpts = cmdOpts.concat([ '-' + k, options[k] ]);
  });

  return cmdOpts;
};
