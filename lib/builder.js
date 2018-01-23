const _ = require('./lodash');
const keylist = require('key-list');
const async = require('async');
const readline = require('readline');
const chalk = require('chalk');
const util = require('util');
const spawn = require('win-spawn');
const opted = require('opted');
const path = require('path');

class Builder {
  constructor(options, context, grunt) {
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

    let PATH = [ path.resolve('node_modules/.bin'), process.env.PATH ].join(':');
    this.env = Object.assign({}, process.env, this.config.env, { PATH });
  }

  setConfig(context) {
    const data = context.data;

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
  }

  buildOptions() {
    // Concat all the options together
    const options = opted(this.options, this.singleDash);
    this.args = _.filter([].concat(this.config.args).concat(options).concat(this.config.rawArgs));
    return this;
  }

  getDynamicValues(cb) {
    // Get the keys to be interpolated
    let msg = this.args.join('||');
    let keys = keylist.getKeys(msg);

    // If there are no keys (i.e. no interpolation), just carry on
    if (!keys.length) {
      return cb(null);
    }

    // Get any values in grunt.option and grunt.config first
    const context = this.populateFromGrunt(keys);

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
  }

  getReadlineValues(keys, context, msg, cb) {
    console.log();
    console.log('Enter values for', chalk.green([ this.cmd, this.target ].concat(this.args).join(' ')));

    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    async.reduce(keys, context, (memo, key, next) => {
      this.prompt(key, answer => next(null, Object.assign(memo, { [key]: answer })));
    }, (err, context) => {
      this.rl.close();
      if (err) {
        return this.grunt.fail.fatal(err);
      } else {
        this.template(msg, context);
        cb();
      }
    });
  }

  populateFromGrunt(keys) {
    // Try to get a value from grunt.option and grunt.config
    return _.reduce(keys, (memo, key) => {
      const option = this.grunt.option(key);
      const config = this.grunt.config.get(key);
      _.set(memo, key, option || config || null);
      return memo;
    }, {});
  }

  template(msg, context) {
    this.args = _.template(msg)(context).split('||');
  }

  prompt(name, cb) {
    this.rl.question(`   ${name}: `, cb);
  }

  handleCustomOption(option, next) {
    if (this.config[option]) {
      this.customOptions[option].call(this, this.config[option], next);
    } else {
      next();
    }
  }

  debug() {
    let inspected = util.inspect({
      env: this.env,
      cwd: this.config.cwd
    });

    this.grunt.log.writeln(`Command: ${chalk.cyan([ this.cmd, this.target ].concat(this.args).join(' '))}`);
    this.grunt.log.writeln();
    this.grunt.log.writeln(`Options: ${chalk.cyan(inspected)}`);

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
  }

  callComplete(code, stderr, stdout) {
    let err = null;
    if (code || stderr) {
      err = new Error(stderr);
      err.code = code;
    }
    this.config.onComplete(err, stdout, this.callback);
  }

  spawn() {
    // Create the child process
    const child = spawn(this.cmd, [this.target].concat(this.args), {
      env: this.env,
      cwd: this.config.cwd
    });

    // Capture output for onComplete callback
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (data) => {
      data = data.toString();
      stdout += data;
      if (!this.config.quiet) {
        process.stdout.write(data);
      }
    });

    child.stderr.on('data', (data) => {
      data = data.toString();
      stderr += data;
      if (!this.config.quiet) {
        process.stdout.write(data);
      }
    });

    child.on('close', (code) => {
      // Ignore failures when force is true
      if (this.config.force && code) {
        this.grunt.log.writeln(`${this.cmd}:${this.target} returned code ${code}. Ignoring...`);
        code = 0;
      }

      // Call the complete callback if it exists
      if (this.config.onComplete) {
        this.callComplete(code, stderr, stdout);
      } else {
        // Otherwise, just call done
        this.callback(code);
      }
    });
  }
}

module.exports = Builder;
