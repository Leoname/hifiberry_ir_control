// IR Remote Control Extension for Beocreate
// Server-side code (Node.js)

var version = require("./package.json").version;

module.exports = {
    version: version,
    
    setup: function(options, imports, register) {
        var debug = imports.debug;
        var beo = imports.beo;
        
        debug('IR Remote Control extension loaded.');
        
        register(null, {});
    }
};
