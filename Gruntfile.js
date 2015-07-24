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
        require: 'coffee-script/register'
      },
      unit: {
        src: ['test/helpers.coffee', 'test/**/*.coffee', '!test/integration.coffee']
      },
      integration: {
        src: ['test/helpers.coffee', 'test/integration.coffee']
      }
    },
    travis: {
      options: {
        targets: {
          test: '{{ version }}',
          when: 'v0.12',
          tasks: ['istanbul', 'matrix:v0.12']
        }
      }
    },
    matrix: {
      'v0.12': 'codeclimate-test-reporter < coverage/lcov.info'
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
      unit: {
        options: {
          root: 'lib',
          dir: 'coverage'
        },
        cmd: 'cover grunt mochaTest:unit'
      },
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
          'author=': 'Andrew',
          simple: {
            onComplete: onComplete
          }
        }
      },
      env: {
        options: {
          simple: {
            onComplete: onComplete,
            env: {
              FOO: 'BAR'
            }
          }
        }
      },
      cwd: {
        options: {
          simple: {
            onComplete: onComplete,
            cwd: __dirname + '/test'
          },
          cwd: true
        }
      },
      force: {
        options: {
          simple: {
            onComplete: onComplete,
            force: true
          },
          fail: true
        }
      },
      cmd: {
        options: {
          simple: {
            onComplete: onComplete,
            cmd: 'not-cmd'
          }
        }
      },
      args: {
        options: {
          simple: {
            onComplete: onComplete,
            args: ['jingle', 'bells']
          }
        }
      },
      raw: {
        options: {
          simple: {
            onComplete: onComplete,
            rawArgs: '-- $% "hello" '
          }
        }
      },
      debug: {
        options: {
          simple: {
            onComplete: onComplete,
            debug: true
          }
        }
      },
      stdout: {
        options: {
          simple: {
            onComplete: onComplete,
            debug: {
              stdout: 'Hey banana'
            }
          }
        }
      },
      dynamic: {
        options: {
          simple: {
            onComplete: onComplete
          },
          foo: '{{ foo }}'
        }
      }
    },
    proxy: {},
    'opts-test': {
      custom: {
        options: {
          simple: {
            onComplete: onComplete,
            foo: 'Ned'
          }
        }
      },
      dash: {
        options: {
          simple: {
            onComplete: onComplete
          },
          foo: 'bar'
        }
      }
    },
    'callback-test': {
      cb: {
        options: {
          simple: {
            onComplete: onComplete
          }
        }
      }
    }
  });

  grunt.registerTask('mocha', ['mochaTest']);
  grunt.registerTask('default', ['jshint:all', 'mocha']);
  grunt.registerTask('coverage', ['istanbul']);
  grunt.registerTask('ci', ['jshint:all', 'mocha', 'travis']);
};
