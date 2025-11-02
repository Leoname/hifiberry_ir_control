var extensions = (function() {
    var extensions = {};
    
    extensions["ir-remote-control"] = {
        displayName: "IR Remote Control",
        description: "Control your audio receiver via infrared remote",
        version: "1.0.0",
        hidden: false
    };

    return extensions;
})();

if (typeof module !== 'undefined' && module.exports) {
    module.exports = extensions;
}

