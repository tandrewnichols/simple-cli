module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-mocha-cov');
  grunt.loadNpmTasks('grunt-travis-matrix');
  grunt.loadNpmTasks('grunt-codeclimate-reporter');

  grunt.initConfig({
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
    mochacov: {
      lcov: {
        options: {
          reporter: 'mocha-lcov-reporter',
          instrument: true,
          ui: 'mocha-given',
          require: 'coffee-script/register',
          output: 'coverage/coverage.lcov'
        },
        src: ['test/helpers.coffee', 'test/**/*.coffee'],
      },
      html: {
        options: {
          reporter: 'html-cov',
          ui: 'mocha-given',
          require: 'coffee-script/register',
          output: 'coverage/coverage.html'
        },
        src: ['test/helpers.coffee', 'test/**/*.coffee']
      }
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
    codeclimate: {
      options: {
        file: 'coverage/coverage.lcov',
        token: '897166616c6cd6f7cebd180f6ef89c02b1a3f483ba91690159bde9534af7fc19'
      }
    },
    travis: {
      options: {
        targets: {
          test: '{{ version }}',
          when: 'v0.12',
          tasks: ['mochacov:lcov', 'codeclimate']
        }
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
    }
  });

  grunt.registerTask('mocha', ['mochaTest:test']);
  grunt.registerTask('default', ['jshint:all', 'mocha']);
  grunt.registerTask('coverage', ['mochacov:html']);
  grunt.registerTask('ci', ['jshint:all', 'mocha', 'travis']);
};
