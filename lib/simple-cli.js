var _ = require('./lodash');
var v = require('varity');
var async = require('async');
var Builder = require('./builder');

exports.spawn = v('*s*s+osf', function(taskName, description, customOpts, cmd, cb) {
  return function(grunt) {
    grunt.registerMultiTask(taskName, description, function() {
      // Initialize builder
      var builder = new Builder(cmd || taskName, cb, this, grunt, customOpts);

      // Handle all manner of options
      builder.configure().buildOptions().getDynamicValues(function() {

        // Loop over custom options and supply them to the consumer
        async.each(_.keys(customOpts), builder.handleCustomOption.bind(builder), function(err) {
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
});
