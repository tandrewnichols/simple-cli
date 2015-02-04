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
