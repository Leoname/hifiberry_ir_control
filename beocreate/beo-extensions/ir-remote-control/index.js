// IR REMOTE CONTROL FOR BEOCREATE

console.log('IR Remote Control extension file included');

var exec = require("child_process").exec;
var fs = require("fs");

var debug = beo.debug;
var version = require("./package.json").version;

var sources = null;

var settings = {
	irEnabled: true,
	lastCommand: "None"
};

beo.bus.on('general', function(event) {
	console.log('beo.bus.on(general)');		
	if (event.header == "startup") {
		console.log('startup');		
		if (beo.extensions.sources &&
			beo.extensions.sources.setSourceOptions &&
			beo.extensions.sources.sourceDeactivated) {
			sources = beo.extensions.sources;
		}
		
		if (sources) {
			getIRStatus(function(enabled) {
				sources.setSourceOptions("ir-remote-control", {
					enabled: enabled,
					aka: "ir-remote-control"
				});
			});
		}
	}
	
	if (event.header == "activatedExtension") {
		console.log('activatedExtension');		
		if (event.content.extension == "ir-remote-control") {
			beo.bus.emit("ui", {target: "ir-remote-control", header: "irSettings", content: settings});
		}
	}
});

beo.bus.on('ir-remote-control', function(event) {
	console.log('beo.bus.on(ir-remote-control)');
	
	if (event.header == "sendCommand") {
		console.log('sendCommand: ' + event.content.command);
		sendIRCommand(event.content.command, function(success, error) {
			if (success) {
				settings.lastCommand = event.content.command;
				beo.bus.emit("ui", {target: "ir-remote-control", header: "irSettings", content: settings});
			}
			if (error) {
				beo.bus.emit("ui", {target: "ir-remote-control", header: "errorSendingCommand", content: {}});
			}
		});
	}
});

function getIRStatus(callback) {
	console.log('SERVER getIRStatus()');
	exec("systemctl is-active --quiet ir-api.service").on('exit', function(code) {
		console.log('getIRStatus code: ' + code);
		if (code == 0) {
			settings.irEnabled = true;
			callback(true);
		} else {
			settings.irEnabled = false;
			callback(false);
		}
	});
}

function sendIRCommand(command, callback) {
	console.log('Sending IR command: ' + command);
	exec("/usr/bin/python3 /opt/hifiberry/ir-remote-control/remote_control.py -c " + command).on('exit', function(code) {
		if (code == 0) {
			if (debug) console.log("IR command sent: " + command);
			callback(true);
		} else {
			callback(false, true);
		}
	});
}

module.exports = {
	version: version,
	isEnabled: getIRStatus
};
