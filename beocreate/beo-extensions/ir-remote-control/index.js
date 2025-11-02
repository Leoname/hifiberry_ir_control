var ir_remote_control = (function() {

    // Extension metadata
    var extensions = {};
    
    extensions.ir_remote_control = {
        displayName: "IR Remote Control",
        description: "Control your audio receiver via infrared remote",
        version: "1.0.0",
        hidden: false
    };

    // Load UI when extension is added to sources
    extensions.ir_remote_control.onSources = function(data) {
        console.log("IR Remote Control extension loaded");
    };

    return extensions;

})();

if (typeof module !== 'undefined' && module.exports) {
    module.exports = ir_remote_control;
}

