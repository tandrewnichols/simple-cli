module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-travis-matrix');
  grunt.loadNpmTasks('grunt-simple-istanbul');
  grunt.loadNpmTasks('grunt-open');
  grunt.loadTasks('test/fixtures/tasks');

  var onComplete = function(err, stdout, done) {
    console.log(stdout);
    done();
  };

  grunt.initConfig({
    open: {
      coverage: {
        path: 'coverage/lcov-report/index.html'
      }
    },
    clean: {
      coverage: 'coverage'
    },
    jshint: {
      options: {
        reporter: require('jshint-stylish'),
        eqeqeq: true,
        es3: true,
        indent: 2,
        newcap: true,
        quotmark: 'single'
      },
      all: ['lib/*.js']
    },
    mochaTest: {
      options: {
        reporter: 'spec',
        ui: 'mocha-given',
        require: 'coffee-script/register',
        timeout: 3000
      },
      unit: {
        src: ['test/helpers.coffee', 'test/**/*.coffee', '!test/integration.coffee']
      },
      integration: {
        src: ['test/helpers.coffee', 'test/integration.coffee']
      }
    },
    travisMatrix: {
      v4: {
        test: function() {
          return /^v4/.test(process.version);
        },
        tasks: ['istanbul:cover']
      }
    },
    watch: {
      tests: {
        files: ['lib/**/*.js', 'test/**/*.coffee'],
        tasks: ['mocha'],
        options: {
          atBegin: true
        }
      }
    },
    istanbul: {
      cover: {
        options: {
          root: 'lib',
          dir: 'coverage',
          simple: {
            args: ['grunt', 'mochaTest:unit']
          }
        }
      }
    },

    // Test commands
    'simple-test': {
      opts: {
        options: {
          fruit: 'banana',
          animal: ['tiger', 'moose'],
          multiWord: true,
          negated: false,
          b: 'quux',
          c: true,
          'author=': 'Andrew'
        },
        onComplete: onComplete
      },
      env: {
        onComplete: onComplete,
        env: {
          FOO: 'BAR'
        }
      },
      cwd: {
        options: {
          cwd: true
        },
        onComplete: onComplete,
        cwd: __dirname + '/test'
      },
      force: {
        options: {
          fail: true
        },
        onComplete: onComplete,
        force: true
      },
      cmd: {
        onComplete: onComplete,
        cmd: 'not-cmd'
      },
      args: {
        onComplete: onComplete,
        args: ['jingle', 'bells']
      },
      raw: {
        onComplete: onComplete,
        rawArgs: '-- $% "hello" '
      },
      debug: {
        onComplete: onComplete,
        debug: true
      },
      stdout: {
        onComplete: onComplete,
        debug: {
          stdout: 'Hey banana'
        }
      },
      dynamic: {
        options: {
          foo: '{{ foo }}'
        },
        onComplete: onComplete
      },
      'dynamic-nested': {
        options: {
          foo: '{{ foo }}'
        },
        onComplete: onComplete,
        args: ['{{ hello.world }}']
      }
    },
    proxy: {},
    'opts-test': {
      custom: {
        onComplete: onComplete,
        foo: 'Ned'
      },
      dash: {
        options: {
          foo: 'bar'
        },
        onComplete: onComplete
      }
    },
    'callback-test': {
      cb: {
        onComplete: onComplete
      }
    }
  });

  grunt.registerTask('mocha', ['mochaTest']);
  grunt.registerTask('default', ['jshint:all', 'mocha']);
  grunt.registerTask('coverage', ['istanbul']);
  grunt.registerTask('ci', ['jshint:all', 'mocha', 'travisMatrix']);
};
