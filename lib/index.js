var cp = require('child_process');
var _ = require('./lodash');
var builder = require('./opt-builder');
var extend = require('config-extend');
var v = require('varity');
var chalk = require('chalk');
var util = require('util');
var async = require('async');

exports.spawn = v('*o*o+osf', function(grunt, context, customOpts, name, cb) {
  var cmd = name || context.name;
  var done = cb || context.async();
  var options = context.options({
    simple: {}
  });
  var target = _.dasherize(context.target);

  // Get options
  var simple = options.simple;
  delete options.simple;
  var debug = grunt.option('debug') || simple.debug;
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

    // Put it all in an object so custom opt handlers can modify it
    var optObj = {
      cmd: cmd,
      target: target,
      args: cmdOpts,
      rawArgs: simple.rawArgs,
      options: opts
    };

    async.each(_.keys(customOpts), function(opt, next) {
      if (simple[opt]) {
        customOpts[opt](simple[opt], optObj, next);    
      } else {
        next();
      }
    }, function(err) {
      if (err) {
        return grunt.fail.fatal(err);
      }

      // In debug mode, just print the command and do nothing else
      if (debug) {
        grunt.log.writeln('Command: ' + chalk.cyan([optObj.cmd, optObj.target].concat(optObj.args).join(' ')));
        grunt.log.writeln('Options: ' + chalk.cyan(util.inspect({ env: simple.env, cwd: simple.cwd })));
        if (simple.onComplete) {
          err = null;
          if (typeof simple.debug !== 'object') {
            simple.debug = {
              stderr: '[DEBUG]: stderr',
              stdout: '[DEBUG]: stdout'
            };
          }
          if (simple.debug.stderr) {
            err = new Error(simple.debug.stderr);
            err.code = 1;
          }
          simple.onComplete(err, simple.debug.stdout || '[DEBUG]: stdout', done);
        } else {
          done();
        }
      } else {
        // Create the child process
        var child;
        if (_.keys(optObj.options).length) {
          child = cp.spawn(optObj.cmd, [optObj.target].concat(optObj.args), optObj.options);
        } else {
          child = cp.spawn(optObj.cmd, [optObj.target].concat(optObj.args));
        }

        // If there's a complete callback, capture the stderr and stdout
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
          // Ignore failures when force is true
          if (simple.force && code) {
            grunt.log.writeln(optObj.cmd + ':' + optObj.target + ' returned code ' + code + '. Ignoring...');
            code = 0;
          }
          
          // Call the complete callback if it exists
          if (simple.onComplete) {
            var err = null;
            if (code || stderr) {
              err = new Error(stderr);
              err.code = code;
            }
            // And pass done for the end user to complete the task
            simple.onComplete(err, stdout, done);
          } else {
            // Otherwise, just call done
            done(code);
          }
        });
      }
    });
  });
});
