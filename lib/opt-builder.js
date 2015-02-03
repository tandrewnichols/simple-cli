var _ = require('./lodash');
var keylist = require('key-list');
var async = require('async');
var readline = require('readline');
var chalk = require('chalk');
var rl;

exports.build = function(options) {
  var flag = [];
  var nonFlag = [];

  // Handle long opts
  var cmdOpts = _(options).keys().reduce(function(memo, key) {
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
        var value = options[key];
        if (!Array.isArray(value)) {
          value = [value];
        }
        // Do in a loop for commands that allow more than one value
        _.each(value, function(v) {
          memo.push('--' + _.dasherize(key));
          // Specifically allow "true" to mean "this flag has no arg with it"
          if (v !== true) {
            memo.push(v);
          }
        });
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
    var value = options[k];
    if (!Array.isArray(value)) {
      value = [value];
    }
    // Do in a loop for commands that allow more than one value
    _.each(value, function(v) {
      cmdOpts = cmdOpts.concat([ '-' + k, v ]);
    });
  });

  return cmdOpts;
};

exports.getDynamicValues = function(grunt, cmd, target, opts, cb) {
  // Get the keys to be interpolated
  var msg = opts.join('||');
  var keys = keylist.getKeys(msg);

  // If there are no keys (i.e. no interpolation), just carry on
  if (!keys.length) {
    return cb(null, opts);
  }

  // Get any values in grunt.option and grunt.config first
  var hasValue = [];
  var context = _.reduce(keys, function(memo, k) {
    var opt = grunt.option(k);
    var conf = grunt.config.get(k);
    if (opt) {
      memo[k] = opt;
      hasValue.push(k);
    } else if (conf) {
      memo[k] = conf;
      hasValue.push(k);
    }
    return memo;
  }, {});

  // Extract the remaining keys
  keys = _.difference(keys, hasValue);

  // If there are still keys, get them via prompt
  if (keys.length) {
    console.log();
    console.log('Enter values for', chalk.green([cmd, target].concat(opts).join(' ')));
    rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  }
  async.reduce(keys, context, function(context, key, next) {
    exports.prompt(key, function(answer) {
      context[key] = answer; 
      next(null, context);
    });
  }, function(err, context) {
    if (rl) {
      rl.close();     
    }
    if (err) {
      cb(err);
    } else {
      cb(null, _.template(msg)(context).split('||'));
    }
  });
};

exports.prompt = function(name, cb) {
  rl.question('   ' + name + ': ', cb);
};
