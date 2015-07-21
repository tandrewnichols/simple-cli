var _ = require('./lodash');
var keylist = require('key-list');
var async = require('async');
var readline = require('readline');
var chalk = require('chalk');
var extend = require('config-extend');
var util = require('util');
var spawn = require('win-spawn');
var opted = require('opted');

var Builder = module.exports = function Builder (options, context, grunt) {
  // Save off all the things
  this.cmd = options.cmd || options.task;
  this.done = options.callback || context.async();
  this.options = context.options({
    simple: {
      args: [],
      rawArgs: [],
      env: {}
    }
  });
  this.config = this.options.simple;
  delete this.options.simple;
  this.debugOn = grunt.option('debug') || this.config.debug;
  this.context = context;
  this.grunt = grunt;
  this.customOptions = options.options;
  this.env = extend({}, process.env, this.config.env);
};

Builder.prototype.configure = function() {
  var data = this.context.data;

  // If data is not an object, then the short form is being used, where
  // the entire grunt target is just a string or array that makes up
  // the command to run.
  if (!_.isPlainObject(data)) {

    // Standardize to an array
    if (typeof data === 'string') {
      data = data.split(' ');
    }

    // The first arg is the command and the rest are options
    this.config.cmd = data.shift();
    this.config.args = data;
  }

  // Target equates to the binary command, e.g. "commit" in "git commit"
  this.target = this.config.cmd || _.dasherize(this.context.target);

  // If args is a string, make an array. This will only happen if args
  // are specified on the "simple" property in the task configuration.
  if (typeof this.config.args === 'string') {
    this.config.args = this.config.args.split(' ');
  }

  return this;
};

Builder.prototype.buildOptions = function() {
  // Concat all the options together
  this.args = [].concat(this.config.args).concat(opted(this.options)).concat(this.config.rawArgs);
  return this;
};

Builder.prototype.getDynamicValues = function(cb) {
  // Get the keys to be interpolated
  var msg = this.args.join('||');
  var keys = keylist.getKeys(msg);

  // If there are no keys (i.e. no interpolation), just carry on
  if (!keys.length) {
    return cb(null);
  }

  // Get any values in grunt.option and grunt.config first
  var context = this.populateFromGrunt(keys);

  // Extract the remaining keys
  keys = _(context).keys().filter(function(key) {
    return context[key] === null;
  }).value();

  // If there aren't more keys, apply what we've got
  if (!keys.length) {
    this.template(msg, context);
    return cb();
  }

  this.getReadlineValues(keys, context, msg, cb);
};

Builder.prototype.getReadlineValues = function(keys, context, msg, cb) {
  var self = this;

  console.log();
  console.log('Enter values for', chalk.green([this.cmd, this.target].concat(this.args).join(' ')));
  this.rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  async.reduce(keys, context, function(memo, key, next) {
    self.prompt(key, function(answer) {
      memo[key] = answer; 
      next(null, memo);
    });
  }, function(err, context) {
    self.rl.close();     
    if (err) {
      return self.grunt.fail.fatal(err);
    } else {
      self.template(msg, context);
      cb();
    }
  });
};

Builder.prototype.populateFromGrunt = function(keys) {
  var self = this;
  // Try to get a value from grunt.option and grunt.config
  return _.reduce(keys, function(memo, key) {
    var option = self.grunt.option(key);
    var config = self.grunt.config.get(key);
    memo[key] = option || config || null;
    return memo;
  }, {});
};

Builder.prototype.template = function(msg, context) {
  this.args = _.template(msg)(context).split('||');
};

Builder.prototype.prompt = function(name, cb) {
  this.rl.question('   ' + name + ': ', cb);
};

Builder.prototype.handleCustomOption = function(option, next) {
  if (this.config[option]) {
    this.customOptions[option](this.config[option], this, next);    
  } else {
    next();
  }
};

Builder.prototype.debug = function() {
  this.grunt.log.writeln('Command: ' + chalk.cyan([this.cmd, this.target].concat(this.args).join(' ')));
  this.grunt.log.writeln();
  this.grunt.log.writeln('Options: ' + chalk.cyan(util.inspect({ env: this.env, cwd: this.config.cwd })));
  if (this.config.onComplete) {
    if (typeof this.config.debug !== 'object') {
      this.config.debug = {
        stderr: '[DEBUG]: stderr',
        stdout: '[DEBUG]: stdout'
      };
    }
    this.callComplete(1, this.config.debug.stderr, this.config.debug.stdout);
  } else {
    this.done();
  }
};

Builder.prototype.callComplete = function(code, stderr, stdout) {
  var err = null;
  if (code || stderr) {
    err = new Error(stderr);
    err.code = code;
  }
  this.config.onComplete(err, stdout, this.done);
};

Builder.prototype.spawn = function() {
  // Create the child process
  var self = this;
  var child = spawn(this.cmd, [this.target].concat(this.args), { env: this.env, cwd: this.config.cwd });

  // Capture output for onComplete callback
  var stdout = '';
  var stderr = '';
  child.stdout.on('data', function(data) {
    stdout += data.toString();
  });
  child.stderr.on('data', function(data) {
    stderr += data.toString();
  });

  child.on('close', function(code) {
    // Ignore failures when force is true
    if (self.config.force && code) {
      self.grunt.log.writeln(self.cmd + ':' + self.target + ' returned code ' + code + '. Ignoring...');
      code = 0;
    }
    
    // Call the complete callback if it exists
    if (self.config.onComplete) {
      self.callComplete(code, stderr, stdout);
    } else {
      // Otherwise, just call done
      self.done(code);
    }
  });
};
