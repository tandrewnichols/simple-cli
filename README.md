[![Build Status](https://travis-ci.org/tandrewnichols/simple-cli.png)](https://travis-ci.org/tandrewnichols/simple-cli) [![downloads](http://img.shields.io/npm/dm/simple-cli.svg)](https://npmjs.org/package/simple-cli) [![npm](http://img.shields.io/npm/v/simple-cli.svg)](https://npmjs.org/package/simple-cli) [![Code Climate](https://codeclimate.com/github/tandrewnichols/simple-cli/badges/gpa.svg)](https://codeclimate.com/github/tandrewnichols/simple-cli) [![Test Coverage](https://codeclimate.com/github/tandrewnichols/simple-cli/badges/coverage.svg)](https://codeclimate.com/github/tandrewnichols/simple-cli) [![dependencies](https://david-dm.org/tandrewnichols/simple-cli.png)](https://david-dm.org/tandrewnichols/simple-cli)

# simple-cli

Gruntify command-line APIs with ease.

## Installation

```bash
npm install --save simple-cli
```

## Usage

This module is intended to be used with grunt to make writing plugin wrappers for command line tools easier to do. In your grunt task declaration, require this module and invoke it as follows:

```javascript
var cli = require('simple-cli');

// Or "npm" or "hg" or "bower" etc.
module.exports = cli('git');
```

Yes, that is _all_ that is necessary to build a fully functioning git plugin for grunt.

This module allows any command on the executable to be invoked as a target with any options specified (camel-cased) under options. It basically makes it possible to do anything the executable can do _in grunt_. Even options not normally a part of the tool (i.e. from a branch or fork) can be invoked with `simple-cli` because `simple-cli` doesn't allow options from a list of known options like most plugins for executables do. It, instead, assumes that the end-user _actually does know what he or she is doing_ and that he or she knows, or can look up, the available options. Below are the kinds of options that can be specified.

## Options on the executable

Let's write a wrapper for the super-awesome (and totally made up) `blerg` executable. First, we write the wrapper and publish it as `grunt-blerg`:

```javascript
var cli = require('simple-cli');

module.exports = function(grunt) {
  grunt.registerMultiTask('blerg', 'A wrapper for blerg-cli', function() {
    cli.spawn(grunt, this);
  });
};
```

Done. Now we can blerg on the command line via grunt! Let's see how an end-user would consume our new library.

#### Long options

You can specify any long option under options with a corresponding value.

```js
grunt.initConfig({
  blerg: {
    shazzam: {
      options: {
        foo: 'bar'
      }
    }
  }
});
```

This will run `blerg shazzam --foo bar`.

#### Multi-word options

Multi-word options work too.

```js
grunt.initConfig({
  blerg: {
    awesome: {
      options: {
        fooBar: 'baz'
      }
    }
  }
});
```

This will run `blerg awesome --foo-bar baz`. Note the camel-casing for options with hyphens.

#### Boolean options

But not all options have values. `blerg`, for example, has that super-user `--banana` option.

```js
grunt.initConfig({
  blerg: {
    jazzhands: {
      options: {
        banana: true
      }
    }
  }
});
```

This will run `blerg jazzhands --banana`.

#### Short options

You can also use short options.

```js
grunt.initConfig({
  blerg: {
    wasabi: {
      options: {
        a: 'foo'
      }
    }
  }
});
```

This will run `blerg wasabi -a foo`.

#### Short boolean options

And short options as booleans.

```js
grunt.initConfig({
  blerg: {
    hashbang: {
      options: {
        a: true
      }
    }
  }
});
```

This will run `blerg hashbang -a`.

#### Options with equal signs

Some libraries have weird "="-style options. Like git. And blerg.

```js
grunt.initConfig({
  blerg: {
    nafblat: {
      options: {
        'bloogs=': 'meep'
      }
    }
  }
});
```

This will run `blerg nafblat --bloogs=meep`.

#### Arrays of options

You can also specify the same option more than once by passing an array.

```js
grunt.initConfig({
  blerg: {
    murica: {
      options: {
        a: ['foo', 'bar'],
        fruit: ['banana', 'kiwi']
      }
    }
  }
});
```

This will run `blerg murica -a foo -a bar --fruit banana --fruit kiwi`.

## Simple cli options

There are also some library specific options. Options about how simple cli itself behaves are placed under the `simple` key.

#### env

Supply additional environment variables to the child process.

```js
grunt.initConfig({
  blerg: {
    hoodoo: {
      options: {
        simple: {
          env: {
            FOO: 'bar'
          }
        }
      }
    }
  }
});
```

Like running `FOO=bar blerg hoodoo`.

#### cwd

Set the current working directory for the child process.

```js
grunt.initConfig({
  blerg: {
    jackwagon: {
      options: {
        simple: {
          cwd: './test'
        }
      }
    }
  }
});
```

Runs `blerg jackwagon`, but in the `./test` directory.

#### force

If the task fails, don't halt the entire task chain. Note that this is different that grunt's own `force` option. Really all this does is consume any error thrown . . . and simply ignore it.

```js
grunt.initConfig({
  blerg: {
    muncher: {
      options: {
        simple: {
          force: true
        }
      }
    }
  }
});
```

#### onComplete

A callback to handle the stdout and stderr streams. `simple-cli` aggregates the stdout and stderr data output and will supply the final strings to the `onComplete` function. This function should have the signature `function(err, stdout, callback)` where `err` is an error object containing the stderr stream (if any errors were reported) and the code returned by the child process (as `err.code`), `stdout` is a string, and `callback` is a function. The callback must be called with a falsy value to complete the task (calling it with a truthy value - e.g. `1` - will fail the task).

```js
grunt.initConfig({
  blerg: {
    portmanteau: {
      options: {
        simple: {
          onComplete: function(err, stdout, callback) {
            if (err) {
              grunt.fail.fatal(err.message, err.code);
            } else {
              grunt.config.set('portmanteau', stdout);
              callback();
            }
          });
        }
      }
    }
  }
});
```

#### cmd

An alternative sub-command to call on the cli. This is useful when you want to create multiple targets that call the same command with different options/parameters. If this value is present, it will be used instead of the grunt target as the first argument to the executable.

```js
grunt.initConfig({
  // Using git as a real example
  git: {
    pushOrigin: {
      options: {
        simple: {
          cmd: 'push',
          args: ['origin', 'master']
        }
      }
    },
    pushHeroku: {
      options: {
        simple: {
          cmd: 'push',
          args: 'heroku master'
        }
      }
    }
  }
});
```

Running `grunt git:pushOrigin` will run `git push origin master` and running `grunt git:pushHeroku` will run `git push heroku master`.

#### args

Additional, non-flag arguments to pass to the executable. These can be passed as an array (as in `git:pushOrigin` above) or as a single string with arguments separated by a space (as in `git:pushHeroku` above). Note that, if you need to use spaces inside an argument, you will need to use the array syntax, since `simple-cli` will split a string on spaces.

#### rawArgs

`rawArgs` is a catch all for any arguments to the executable that can't be handled (for whatever reason) with the options above (e.g. the path arguments in some git commands: `git checkout master -- config/production.json`). Anything in `rawArgs` will be concatenated to the end of all the normal args.

```js
grunt.initConfig({
  git: {
    checkout: {
      options: {
        simple: {
          args: ['master'],
          rawArgs: '-- config/production.json'
        }
      }
    }
  }
});
```

#### debug

Similar to `--dry-run` in many executables. This will log the command that will be spawned in a child process without actually spawning it. Additionally, if you have an onComplete handler, fake stderr and stdout will be passed to this handler, simulating the real task. If you want to use specific stderr/stdout messages, `debug` can also be an object with `stderr` and `stdout` properties that will be passed to the onComplete handler.

```js
grunt.initConfig({
  blerg: {
    'waffle-iron': {
      options: {
        simple: {
          // Invoked with default fake stderr/stdout
          onComplete: function(err, stdout, callback) {
            console.log(err.message, stdout);
            callback();
          },
          debug: true
        }
      }
    },
    'wilty-salad': {
      options: {
        simple: {
          onComplete: function(err, stdout, callback) {
            console.log(err.message, stdout); // Logs 'foo bar'
            callback();
          },
          debug: {
            stderr: 'foo',
            stdout: 'bar'
          }
        }
      }
    }
  }
});
```

Additionally, you can pass the `--debug` option to grunt itself to enable the above behavior in an ad hoc manner (e.g. `grunt blerg:wilty-salad --debug`).

## Dynamic values

Sometimes you just don't know what values you want to supply to an executable until you're ready to use it. That makes it hard to put into a task. `simple-cli` supports dynamical values (via interpolation) which can be supplied in any of three ways:

#### via command line options to grunt (e.g. grunt.option)

Supply the value when you call the task itself.

```js
grunt.initConfig({
  git: {
    push: {
      options: {
        simple: {
          // You can also do this as a string, but note that simple-cli splits
          // string args on space, so you wouldn't be able to put space INSIDE
          // the interpolation. You'd have to say args: '{{remote}} master'
          args: ['{{ remote }}', 'master']
        }
      }
    }
  }
});
```

If the above was invoked with `grunt git:push --remote origin` the final command would be `git push origin master`.

#### via grunt.config

This is primarily useful if you want the result of another task to determine the value of an argument. For instance, maybe in another task you say `grunt.config.set('remote', 'heroku')`, then the task above would run `git push heroku master`.

#### via prompt

If `simple-cli` can't find an interpolation value via `grunt.option` or `grunt.config`, it will prompt you for one on the terminal. Thus you could do something like:

```js
grunt.initConfig({
  git: {
    commit: {
      options: {
        message: '{{ message }}'
      }
    }
  }
});
```

and automate commits, while still supplying an accurate commit message.

## Invoking simple cli

To setup the wrapper for an executable, invoke `require('simple-cli').spawn`. There are two required parameters, `grunt` and `this` (the context of the task). So the simplest invocation looks like:

```js
var cli = require('simple-cil');

grunt.registerMultiTask('foo', 'Wraps the foo executable', function() {
  cli.spawn(grunt, this);
});
```

Additionally, however, you can pass the following parameters to customize the tool for your particular wrapper:

#### options

The options object is actually just a way to extend the `simple-cli` API. Keys in the object are options allowed under `options.simple` and the values are the handlers for those options. So if you need more cowbell in your cli wrapper, you can do that:

```js
var cli = require('simple-cil');

grunt.registerMultiTask('foo', 'Wraps the foo executable', function() {
  cli.spawn(grunt, this, {
    moreCowbell: function(val, config, cb) {
      // I've got a fever...
    }
  });
});
```

The handlers for custom opts are called immediately before the child process is spawned (so all the arguments have already been aggregated and put in the right form). The parameters passed to the handler are the value supplied by the user, an object containing all possible arguments for the child process, and a callback. The config object has the following keys:

* cmd - The executable
* target - The sub-command on the executable
* args - Everything from `options.simple.args` first, followed by all the flags passed under options
* rawArgs - Same as `options.simple.rawArgs`
* options - The options passed to the child process (including `cwd` and `env`)

#### cmd

`simple-cli` assumes that the executable being wrapped is also the name of the grunt task. If, for some reason, this is not the case, you can pass the actual executable name to `spawn`:

```js
var cli = require('simple-cil');

grunt.registerMultiTask('foo', 'Wraps the foo executable', function() {
  // Invokes the executable "foobar" NOT "foo"
  cli.spawn(grunt, this, 'foobar');
});
```

#### callback

`simple-cli` will use the grunt async callback as it's final callback, unless one is supplied. If you supply one, however, you must manage the async task yourself.

```js
var cli = require('simple-cil');

grunt.registerMultiTask('foo', 'Wraps the foo executable', function() {
  var done = this.async();
  cli.spawn(grunt, this, function(){
    // Do other stuff

    // Call done so that grunt knows to run the next task
    done();
  });
});
```

## Shortcut configurations

For very simple tasks, you can define the task body as an array or string, rather than as an object, as all the above examples have been.

```js
grunt.initConfig({
  git: {
    // will invoke "git push origin master"
    origin: ['push', 'origin', 'master'],

    // will invoke "git pull upstream master"
    upstream: 'pull upstream master'
  }
});
