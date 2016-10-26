var _ = require('./lodash');
var async = require('async');
var Builder = require('./builder');

module.exports = function(options) {
  // If options is just the executable name, make it an object
  if (typeof options === 'string') {
    options = {
      task: options
    };
  }

  options.description = options.description || 'A simple-cli grunt wrapper for ' + (options.cmd || options.task);

  return function(grunt) {
    grunt.registerMultiTask(options.task, options.description, function() {
      // Initialize builder
      var builder = new Builder(options, this, grunt);

      // Handle all manner of options
      builder.buildOptions().getDynamicValues(function() {

        // Loop over custom options and supply them to the consumer
        async.each(_.keys(options.options), builder.handleCustomOption.bind(builder), function(err) {
          if (err) {
            return grunt.fail.fatal(err);
          }

          // In debug mode, just print the command and do nothing else.
          // Otherwise, spawn the process.
          if (builder.debugOn) {
            builder.debug();
          } else {
            builder.spawn();
          }
        });
      });
    });
  };
};
