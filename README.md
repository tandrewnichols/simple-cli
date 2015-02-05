[![Build Status](https://travis-ci.org/tandrewnichols/simple-cli.png)](https://travis-ci.org/tandrewnichols/simple-cli) [![downloads](http://img.shields.io/npm/dm/simple-cli.svg)](https://npmjs.org/package/simple-cli) [![npm](http://img.shields.io/npm/v/simple-cli.svg)](https://npmjs.org/package/simple-cli) [![Code Climate](https://codeclimate.com/github/tandrewnichols/simple-cli/badges/gpa.svg)](https://codeclimate.com/github/tandrewnichols/simple-cli) [![Test Coverage](https://codeclimate.com/github/tandrewnichols/simple-cli/badges/coverage.svg)](https://codeclimate.com/github/tandrewnichols/simple-cli) [![dependencies](https://david-dm.org/tandrewnichols/simple-cli.png)](https://david-dm.org/tandrewnichols/simple-cli)

[![NPM info](https://nodei.co/npm/simple-cli.png?downloads=true)](https://nodei.co/npm/simple-cli.png?downloads=true)

# simple-cli

Gruntify command-line APIs with ease.

## Installation

```bash
npm install --save simple-cli
```

## Usage

This module is simple to use (hence the name). In your grunt task declaration, require this module and invoke it as follows:

```javascript
var cli = require('simple-cli');

module.exports = function(grunt) {
  // Or "npm" or "hg" or "bower" etc.
  grunt.registerMultiTask('git', 'A git wrapper', function() {
    cli.spawn(grunt, this);
  });
};
```

Yes, that is _all_ that is necessary to build a fully functioning git plugin for grunt.

## Options on the wrapped CLI

This module allows any command on the wrapped cli to be invoked as a target with any options specified (camel-cased) under options. It basically makes it possible to do anything the CLI tool can do _in grunt_. Even options not normally a part of the tool (i.e. from a branch or fork) can be invoked with `simple-cli` because `simple-cli` doesn't allow options from a list of known options like most plugins for CLI tools do. It, instead, assumes that the end-user _actually does know what he or she is doing_ and that he or she knows, or can look up, the available options. Here are the kinds of options that can be specified:

#### Long options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        foo: 'bar'
      }
    }
  }
});
```

This will run `cli target --foo bar`

#### Multi-word options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        fooBar: 'baz'
      }
    }
  }
});
```

This will run `cli target --foo-bar baz`

#### Boolean options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        foo: true
      }
    }
  }
});
```

This will run `cli target --foo`

#### Short options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        a: 'foo'
      }
    }
  }
});
```

This will run `cli target -a foo`

#### Short boolean options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        a: true
      }
    }
  }
});
```

This will run `cli target -a`

#### Multiple short options grouped together

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        a: true,
        b: true,
        c: 'foo'
      }
    }
  }
});
```

This will run `cli target -ab -c foo`

#### Options with equal signs

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        'author=': 'tandrewnichols'
      }
    }
  }
});
```

This will run `cli target --author=tandrewnichols`

#### Arrays of options

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        a: ['foo', 'bar'],
        greeting: ['hello', 'goodbye']
      }
    }
  }
});
```

This will run `cli target -a foo -a bar --greeting hello --greeting goodbye`

## Simple cli options

Options about how simple cli itself behaves are placed under the `simple` key.

#### env

Supply additional environment variables to the child process.

```js
grunt.initConfig({
  cli: {
    target: {
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

#### cwd

Set the current working directory for the child process.

```js
grunt.initConfig({
  cli: {
    target: {
      options: {
        simple: {
          cwd: './test'
        }
      }
    }
  }
});
```

#### force

If the task fails, don't halt the entire task chain.

```js
grunt.initConfig({
  cli: {
    target: {
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
  cli: {
    target: {
      options: {
        simple: {
          onComplete: function(err, stdout, callback) {
            if (err) {
              grunt.fail.fatal(err.message, err.code);
            } else {
              grunt.config.set('cli output', stdout);
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

Additional, non-flag arguments to pass to the executable. These can be passed as an array (as in `git:pushOrigin` above) or as a single string with arguments separated by a space (as in `git:pushHeroku` above).

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
  cli: {
    target: {
      options: {
        simple: {
          // Invoked with default fake stderr/stdout
          onComplete: function(err, stdout, callback) {
            console.log(arguments);
          },
          debug: true
        }
      }
    },
    target2: {
      options: {
        simple: {
          // Invoked with 'foo' and 'bar'
          onComplete: function(err, stdout, callback) {
            console.log(arguments);
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

Additionally, you can pass the `--debug` option to grunt itself to enable the above behavior in an ad hoc manner.
