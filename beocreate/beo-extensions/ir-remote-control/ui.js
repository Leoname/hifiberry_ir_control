// IR Remote Control UI JavaScript

(function() {
    const API_URL = 'http://localhost:8089';
    let commandLog = [];
    const MAX_LOG_ENTRIES = 10;

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initializeButtons();
        startStatusPolling();
    });

    function initializeButtons() {
        // Add click handlers to all IR buttons
        const buttons = document.querySelectorAll('.ir-button');
        buttons.forEach(button => {
            button.addEventListener('click', function() {
                const command = this.getAttribute('data-command');
                if (command) {
                    sendCommand(command, this);
                }
            });
        });
    }

    function sendCommand(command, buttonElement) {
        // Visual feedback
        buttonElement.classList.add('sending');
        updateStatus('Sending...', command);

        // Send command to API
        fetch(`${API_URL}/api/send`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ command: command })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                updateStatus('Success', command);
                addLogEntry(command, 'success');
            } else {
                updateStatus('Failed', command);
                addLogEntry(command, 'error', data.error || 'Unknown error');
            }
        })
        .catch(error => {
            console.error('Error sending command:', error);
            updateStatus('Error', command);
            addLogEntry(command, 'error', error.message);
        })
        .finally(() => {
            // Remove visual feedback after animation
            setTimeout(() => {
                buttonElement.classList.remove('sending');
            }, 500);
        });
    }

    function updateStatus(status, command) {
        const statusElement = document.getElementById('command-status');
        const commandElement = document.getElementById('last-command');
        
        if (statusElement) {
            statusElement.textContent = status;
        }
        
        if (commandElement && command) {
            commandElement.textContent = formatCommandName(command);
        }
    }

    function formatCommandName(command) {
        // Convert command_name to Command Name
        return command
            .split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    function addLogEntry(command, status, error = null) {
        const now = new Date();
        const timeString = now.toLocaleTimeString();
        
        const entry = {
            time: timeString,
            command: formatCommandName(command),
            status: status,
            error: error
        };
        
        commandLog.unshift(entry);
        
        // Keep only last MAX_LOG_ENTRIES
        if (commandLog.length > MAX_LOG_ENTRIES) {
            commandLog = commandLog.slice(0, MAX_LOG_ENTRIES);
        }
        
        updateLogDisplay();
    }

    function updateLogDisplay() {
        const logContainer = document.getElementById('command-log');
        if (!logContainer) return;
        
        if (commandLog.length === 0) {
            logContainer.innerHTML = '<div class="log-item">Waiting for commands...</div>';
            return;
        }
        
        logContainer.innerHTML = commandLog.map(entry => `
            <div class="log-item">
                <span class="log-time">${entry.time}</span>
                <span class="log-command">${entry.command}</span>
                <span class="log-status ${entry.status}">${entry.status.toUpperCase()}</span>
            </div>
        `).join('');
    }

    function startStatusPolling() {
        // Poll status every 5 seconds (optional - for future enhancements)
        setInterval(() => {
            fetch(`${API_URL}/api/status`)
                .then(response => response.json())
                .then(data => {
                    // Could update UI with receiver status if available
                    console.log('Status:', data);
                })
                .catch(error => {
                    console.log('Status polling error (this is normal if API is not running):', error);
                });
        }, 5000);
    }

    // Expose functions globally if needed
    window.irRemoteControl = {
        sendCommand: sendCommand,
        updateStatus: updateStatus
    };

})();

