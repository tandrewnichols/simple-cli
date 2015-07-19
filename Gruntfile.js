module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-travis-matrix');
  grunt.loadNpmTasks('grunt-simple-istanbul');

  grunt.initConfig({
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
      test: {
        src: ['test/helpers.coffee', 'test/**/*.coffee']
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
        cmd: 'cover grunt mocha'
      },
    }
  });

  grunt.registerTask('mocha', ['mochaTest:test']);
  grunt.registerTask('default', ['jshint:all', 'mocha']);
  grunt.registerTask('coverage', ['istanbul']);
  grunt.registerTask('ci', ['jshint:all', 'mocha', 'travis']);
};
