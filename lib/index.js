var cp = require('child_process');
var _ = require('lodash');
_.mixin(require('underscore.string'));
var builder = require('./opt-builder');

exports.spawn = function(grunt, context, cmd, done) {
  var options = context.options();
  var target = _.dasherize(context.target);

  // Get options
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
    var opts = { cwd: options.cwd || process.cwd(), stdio: options.stdio || 'inherit' };
    if (options.stdio === false) {
      delete opts.stdio; 
    }
    var child = cp.spawn(cmd, [target].concat(cmdOpts), opts);

    // Listen if we have emitters and stdio is not false
    ['stdout', 'stderr'].forEach(function(fd){
      if (child[fd] && options.stdio !== false) {
        child[fd].on('data', function(data) {
          grunt.log.writeln(data.toString());
        });
      }
    });

    child.on('close', function(code) {
      if (options.force && code) {
        grunt.log.writeln(cmd + ':' + context.target + ' returned code ' + code + '. Ignoring...');
        done(0);
      } else {
        done(code);
      }
    });
  });
};
