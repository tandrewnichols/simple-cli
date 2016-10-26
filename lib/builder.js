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
  this.singleDash = options.singleDash;
  this.done = context.async();
  this.callback = options.callback ? options.callback.bind(this) : this.done;
  this.options = context.options({});
  this.context = context;
  this.setConfig(context);
  this.debugOn = grunt.option('debug') || this.config.debug;
  this.grunt = grunt;
  this.customOptions = options.options;
  this.env = extend({}, process.env, this.config.env);
};

Builder.prototype.setConfig = function(context) {
  var data = context.data;

  // If data is not an object, then the short form is being used, where
  // the entire grunt target is just a string or array that makes up
  // the command to run.
  if (!_.isPlainObject(data)) {
    this.config = {
      args: data,
      rawArgs: [],
      env: {}
    };
    this.target = _.kebabCase(context.target);
  } else {
    this.config = _.defaults(_.omit(data, 'options'), {
      cmd: null,
      args: [],
      rawArgs: [],
      env: {}
    });
    this.target = this.config.cmd || _.kebabCase(context.target);
  }

  if (typeof this.config.args === 'string') {
    this.config.args = this.config.args.split(' ');
  }
};

Builder.prototype.buildOptions = function() {
  // Concat all the options together
  var options = opted(this.options, this.singleDash);
  this.args = _.filter([].concat(this.config.args).concat(options).concat(this.config.rawArgs));
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
    _.set(memo, key, option || config || null);
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
    this.customOptions[option].call(this, this.config[option], next);
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
    this.callback();
  }
};

Builder.prototype.callComplete = function(code, stderr, stdout) {
  var err = null;
  if (code || stderr) {
    err = new Error(stderr);
    err.code = code;
  }
  this.config.onComplete(err, stdout, this.callback);
};

Builder.prototype.spawn = function() {
  // Create the child process
  var self = this;
  var child = spawn(this.cmd, [this.target].concat(this.args), { env: this.env, cwd: this.config.cwd });

  // Capture output for onComplete callback
  var stdout = '';
  var stderr = '';
  child.stdout.on('data', function(data) {
    data = data.toString();
    stdout += data;
    if (!self.config.quiet) {
      process.stdout.write(data);
    }
  });
  child.stderr.on('data', function(data) {
    data = data.toString();
    stderr += data;
    if (!self.config.quiet) {
      process.stdout.write(data);
    }
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
      self.callback(code);
    }
  });
};
