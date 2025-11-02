// IR Remote Control Client-Side JavaScript
// This runs in the browser

var irRemoteControl = (function() {
    var statusRequest = null;
    var updateInterval = 2000; // Update every 2 seconds
    var commandLog = [];
    var MAX_LOG_ENTRIES = 10;
    
    // Get API base URL - use current hostname, not localhost
    var API_BASE = window.location.protocol + '//' + window.location.hostname + ':8089';
    console.log('IR API Base URL:', API_BASE);
    
    // Start updates when the extension is shown
    function startStatusUpdates() {
        if (statusRequest) clearInterval(statusRequest);
        
        statusRequest = setInterval(updateStatus, updateInterval);
        
        // Initial update
        updateStatus();
    }
    
    function updateStatus() {
        console.log('Fetching IR status from API...');
        
        var xhr = new XMLHttpRequest();
        xhr.open("GET", API_BASE + "/api/status", true);
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    try {
                        var status = JSON.parse(xhr.responseText);
                        processStatus(status);
                    } catch (e) {
                        console.error('Error parsing status JSON:', e);
                    }
                } else {
                    console.warn('IR API not responding (status: ' + xhr.status + ')');
                }
            }
        };
        
        xhr.send();
    }
    
    function processStatus(status) {
        // Update last command if available
        if (status.last_command && status.last_command !== "None") {
            updateDisplay('ir-last-command', formatCommandName(status.last_command));
        }
        
        // Update status
        if (status.last_status) {
            updateDisplay('ir-status', status.last_status);
        }
    }
    
    function updateDisplay(elementId, value) {
        var element = document.getElementById(elementId);
        if (element) {
            element.textContent = value;
        }
    }
    
    function sendCommand(command) {
        console.log('Sending IR command: ' + command);
        
        // Update UI immediately
        updateDisplay('ir-status', 'Sending...');
        updateDisplay('ir-last-command', formatCommandName(command));
        addLogEntry(command, 'sending');
        
        var xhr = new XMLHttpRequest();
        xhr.open("POST", API_BASE + "/api/send", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        if (response.success) {
                            updateDisplay('ir-status', 'Success');
                            updateLogEntry(command, 'success');
                            console.log('IR command sent successfully');
                        } else {
                            updateDisplay('ir-status', 'Failed');
                            updateLogEntry(command, 'error');
                            showError('Failed to send command: ' + (response.error || 'Unknown error'));
                        }
                    } catch (e) {
                        console.error('Error parsing response JSON:', e);
                        updateDisplay('ir-status', 'Error');
                        updateLogEntry(command, 'error');
                        showError('Invalid response from API');
                    }
                } else {
                    console.error('Error sending command (status: ' + xhr.status + ')');
                    updateDisplay('ir-status', 'Error');
                    updateLogEntry(command, 'error');
                    showError('API connection error');
                }
                
                // Reset status after 2 seconds
                setTimeout(function() {
                    updateDisplay('ir-status', 'Ready');
                }, 2000);
            }
        };
        
        xhr.send(JSON.stringify({ command: command }));
    }
    
    function formatCommandName(command) {
        // Convert command_name to Command Name
        return command
            .split('_')
            .map(function(word) { return word.charAt(0).toUpperCase() + word.slice(1); })
            .join(' ');
    }
    
    function addLogEntry(command, status) {
        var now = new Date();
        var timeString = now.toLocaleTimeString();
        
        commandLog.unshift({
            time: timeString,
            command: formatCommandName(command),
            status: status
        });
        
        // Keep only last MAX_LOG_ENTRIES
        if (commandLog.length > MAX_LOG_ENTRIES) {
            commandLog = commandLog.slice(0, MAX_LOG_ENTRIES);
        }
        
        updateLogDisplay();
    }
    
    function updateLogEntry(command, status) {
        if (commandLog.length > 0) {
            commandLog[0].status = status;
            updateLogDisplay();
        }
    }
    
    function updateLogDisplay() {
        var logContainer = document.getElementById('ir-command-log');
        if (!logContainer) return;
        
        if (commandLog.length === 0) {
            logContainer.innerHTML = '<div style="opacity: 0.5;">Waiting for commands...</div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < commandLog.length; i++) {
            var entry = commandLog[i];
            var statusColor = entry.status === 'success' ? '#4caf50' : (entry.status === 'error' ? '#d32f2f' : '#ff9800');
            html += '<div style="padding: 8px 0; border-bottom: 1px solid rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center;">';
            html += '<span style="opacity: 0.7;">' + entry.time + '</span>';
            html += '<span style="flex: 1; padding: 0 10px; font-weight: 500;">' + entry.command + '</span>';
            html += '<span style="color: ' + statusColor + '; font-weight: 600; font-size: 9px; text-transform: uppercase;">' + entry.status + '</span>';
            html += '</div>';
        }
        
        logContainer.innerHTML = html;
    }
    
    function showError(message) {
        var errorElement = document.getElementById('ir-error');
        if (errorElement) {
            errorElement.textContent = message;
            errorElement.style.display = 'block';
            
            setTimeout(function() {
                errorElement.style.display = 'none';
            }, 5000);
        }
    }
    
    // Public API
    return {
        sendCommand: sendCommand,
        startStatusUpdates: startStatusUpdates
    };
    
})();

// Auto-start when extension is activated
setTimeout(function() {
    if (typeof beo !== 'undefined' && beo.bus) {
        beo.bus.on('general', function(event) {
            if (event.header === 'activatedExtension' && event.content.extension === 'ir-remote-control') {
                console.log('IR Remote Control extension activated');
                irRemoteControl.startStatusUpdates();
            }
        });
    }
}, 100);
