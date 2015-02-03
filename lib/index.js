var cp = require('child_process');
var _ = require('./lodash');
var builder = require('./opt-builder');
var extend = require('config-extend');
var v = require('varity');
var chalk = require('chalk');
var util = require('util');

exports.spawn = v('oosf', function(grunt, context, name, cb) {
  var cmd = name || context.name;
  var done = cb || context.async();
  var options = context.options({
    simple: {}
  });
  var target = _.dasherize(context.target);

  // Get options
  var simple = options.simple;
  delete options.simple;
  var cmdOpts = builder.build(options);

  if (!_.isPlainObject(context.data)) {
    var parts = typeof context.data === 'string' ? context.data.split(' ') : context.data;
    simple.cmd = parts.shift();
    simple.args = parts;
  }
  
  // Allow multiple tasks that run the same sub-command
  if (simple.cmd) {
    target = simple.cmd;
  }

  // Get any additional args (either array or string)
  if (typeof simple.args === 'string') {
    simple.args = simple.args.split(' ');
  }

  // Concat all the options together
  cmdOpts = (simple.args || []).concat(cmdOpts).concat(simple.rawArgs || []);
  
  // Get dynamic opt values
  builder.getDynamicValues(grunt, cmd, target, cmdOpts, function(err, cmdOpts) {
    if (err) {
      return grunt.fail.fatal(err);
    }
    // Create child process
    var opts = {};
    if (simple.cwd) {
      opts.cwd = simple.cwd;
    }

    if (simple.env) {
      opts.env = extend({}, process.env, simple.env);
    }

    var child;
    if (simple.debug) {
      grunt.log.writeln('Command: ' + chalk.cyan([cmd, target].concat(cmdOpts).join(' ')));
      grunt.log.writeln('Options: ' + chalk.cyan(util.inspect({ env: simple.env, cwd: simple.cwd })));
    }

    if (_.keys(opts).length) {
      child = cp.spawn(cmd, [target].concat(cmdOpts), opts);
    } else {
      child = cp.spawn(cmd, [target].concat(cmdOpts), opts);
    }

    if (simple.onComplete) {
      var stdout = '';
      var stderr = '';
      child.stdout.on('data', function(data) {
        stdout += data.toString();
      });
      child.stderr.on('data', function(data) {
        stderr += data.toString();
      });
    }

    child.on('close', function(code) {
      if (simple.force && code) {
        grunt.log.writeln(cmd + ':' + context.target + ' returned code ' + code + '. Ignoring...');
        code = 0;
      }
      
      if (simple.onComplete) {
        var err = null;
        if (code || stderr) {
          err = new Error(stderr);
          err.code = code;
        }
        simple.onComplete(err, stdout, done);
      } else {
        done(code);
      }
    });
  });
});
