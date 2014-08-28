var cp = require('child_process');
var _ = require('lodash');
_.mixin(require('underscore.string'));

exports.spawn = function(grunt, context, cmd, done) {
  var options = context.options();
  var target = _.dasherize(context.target);
  var flag = [];
  var nonFlag = [];

  // Build out git options
  var cmdOpts = _(options).omit('cwd', 'stdio', 'force').keys().reduce(function(memo, key) {
    // Allow short options
    if (key.length === 1) {
      if (options[key] === true) flag.push(key);
      else nonFlag.push(key);
    } else {
      if (_.endsWith(key, '=')) {
        memo.push('--' + _.dasherize(key) + options[key]);
      } else {
        memo.push('--' + _.dasherize(key));
        // Specifically allow "true" to mean "this flag has no arg with it"
        if (options[key] !== true) memo.push(options[key]);
      }
    }
    return memo;
  }, []);

  // Collect short options
  if (flag.length) cmdOpts.push('-' + flag.join(''));
  _.each(nonFlag, function(k) {
    cmdOpts = cmdOpts.concat([ '-' + k, options[k] ]);
  });
  
  // Allow multiple tasks that run the same git command
  if (context.data.cmd) {
    var cmdArgs = context.data.cmd.split(' ');
    target = cmdArgs.shift();
    if (target === cmd) target = cmdArgs.shift();
    cmdOpts = cmdArgs.concat(cmdOpts);
  }

  if (context.data.rawArgs) cmdOpts = cmdOpts.concat(context.data.rawArgs);
  
  // Create git process
  var opts = { cwd: options.cwd || process.cwd(), stdio: options.stdio || 'inherit' };
  if (options.stdio === false) delete opts.stdio; 
  var child = cp.spawn(cmd, [target].concat(cmdOpts), opts);

  // Listen if we have emitters and stdio is not false
  if (child.stdout && options.stdio !== false) {
    child.stdout.on('data', function(data) {
      grunt.log.writeln(data.toString());
    });
  }
  if (child.stderr && options.stdio !== false) {
    child.stderr.on('data', function(data) {
      grunt.log.writeln(data.toString());
    });
  }

  child.on('close', function(code) {
    if (options.force && code) {
      grunt.log.writeln(cmd + ':' + context.target + ' returned code ' + code + '. Ignoring...');
      done(0);
    } else done(code);
  });
};
