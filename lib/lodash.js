var _ = require('lodash').runInContext();
_.mixin(require('underscore.string'));
_.templateSettings.interpolate = /\{\{([\s\S]+?)\}\}/g;

module.exports = _;
