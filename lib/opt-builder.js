var _ = require('lodash');
_.templateSettings.interpolate = /\{\{([\s\S]+?)\}\}/g;
var keylist = require('key-list');
var async = require('async');
var readline = require('readline');
var chalk = require('chalk');
var rl;

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
  var msg = opts.join('||');
  var keys = keylist.getKeys(msg);
  if (keys.length) {
    console.log();
    console.log('Enter values for', chalk.green([cmd, target].concat(opts).join(' ')));
    rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  } else {
    return cb(null, opts);
  }
  async.reduce(keys, {}, function(context, key, next) {
    var opt = grunt.option(key);
    if (opt) {
      context[key] = grunt.option(key);
      next(null, context);
    } else {
      exports.prompt(key, function(answer) {
        context[key] = answer; 
        next(null, context);
      });
    }
  }, function(err, context) {
    rl.close();     
    if (err) {
      cb(err);
    } else {
      cb(null, _.template(msg, context).split('||'));
    }
  });
};

exports.prompt = function(name, cb) {
  rl.question('   ' + name + ': ', cb);
};
