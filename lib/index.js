var cp = require('child_process');
var _ = require('./lodash');
var builder = require('./opt-builder');
var extend = require('config-extend');
var v = require('varity');

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
  var execCmd = typeof context.data === 'string' ? context.data : context.data.cmd;
  
  // Allow multiple tasks that run the same git command
  if (execCmd) {
    var cmdArgs = execCmd.split(' ');
    target = cmdArgs.shift();
    if (target === cmd) {
      target = cmdArgs.shift();
    }
    cmdOpts = cmdArgs.concat(cmdOpts);
  }

  if (context.data.rawArgs) {
    cmdOpts = cmdOpts.concat(context.data.rawArgs);
  }
  
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
    console.log(cmd, [target].concat(cmdOpts), opts);
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
