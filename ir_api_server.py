#!/usr/bin/env python3
"""
IR Remote Control API Server for HiFiBerry OS
Provides HTTP API for web interface to send IR commands
"""

import json
import subprocess
import os
import sys
import time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

# Configuration
API_PORT = 8089
IR_CONTROL_SCRIPT = '/opt/hifiberry/ir-remote-control/remote_control.py'
STATUS_FILE = '/opt/hifiberry/ir-remote-control/status.json'

class IRAPIHandler(BaseHTTPRequestHandler):
    
    def _set_headers(self, status=200, content_type='application/json'):
        """Set HTTP response headers"""
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Connection', 'keep-alive')
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
    
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self._set_headers()
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/api/status':
            self.handle_status()
        elif parsed_path.path == '/api/commands':
            self.handle_commands_list()
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
    
    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/api/send':
            self.handle_send_command()
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
    
    def handle_status(self):
        """Return current status"""
        try:
            if os.path.exists(STATUS_FILE):
                try:
                    with open(STATUS_FILE, 'r') as f:
                        status = json.load(f)
                except (json.JSONDecodeError, IOError):
                    # If file is corrupted or being written, return default
                    status = {
                        'last_command': 'None',
                        'last_status': 'Ready',
                        'timestamp': int(time.time())
                    }
            else:
                status = {
                    'last_command': 'None',
                    'last_status': 'Ready',
                    'timestamp': int(time.time())
                }
            
            self._set_headers()
            self.wfile.write(json.dumps(status).encode())
        except Exception as e:
            self._set_headers(500)
            self.wfile.write(json.dumps({
                'error': str(e),
                'last_command': 'None',
                'last_status': 'Error',
                'timestamp': int(time.time())
            }).encode())
    
    def handle_commands_list(self):
        """Return list of available commands"""
        commands = {
            'power': 'Power on/off',
            'mute': 'Mute audio',
            'volume_up': 'Increase volume',
            'volume_down': 'Decrease volume',
            'input_tuner': 'Switch to Tuner',
            'input_phono': 'Switch to Phono',
            'input_cd': 'Switch to CD',
            'input_direct': 'Switch to Direct',
            'input_video1': 'Switch to Video 1',
            'input_video2': 'Switch to Video 2',
            'input_tape1': 'Switch to Tape 1',
            'input_tape2': 'Switch to Tape 2'
        }
        
        self._set_headers()
        self.wfile.write(json.dumps(commands).encode())
    
    def handle_send_command(self):
        """Send an IR command"""
        try:
            # Read request body
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode())
            
            command = data.get('command')
            if not command:
                self._set_headers(400)
                self.wfile.write(json.dumps({
                    'success': False,
                    'error': 'No command specified'
                }).encode())
                return
            
            # Execute the IR control script
            result = subprocess.run(
                ['python3', IR_CONTROL_SCRIPT, '-c', command],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=5
            )
            
            success = result.returncode == 0
            
            # Update status file
            status = {
                'last_command': command,
                'last_status': 'Success' if success else 'Failed',
                'timestamp': int(time.time())
            }
            
            try:
                os.makedirs(os.path.dirname(STATUS_FILE), exist_ok=True)
                with open(STATUS_FILE, 'w') as f:
                    json.dump(status, f)
            except IOError:
                # If we can't write status file, continue anyway
                pass
            
            # Return response
            self._set_headers()
            response = {
                'success': success,
                'command': command,
                'output': result.stdout.decode().strip()
            }
            
            if not success:
                response['error'] = result.stderr.decode().strip()
            
            self.wfile.write(json.dumps(response).encode())
            
        except subprocess.TimeoutExpired:
            self._set_headers(500)
            self.wfile.write(json.dumps({
                'success': False,
                'error': 'Command timeout'
            }).encode())
        except Exception as e:
            self._set_headers(500)
            self.wfile.write(json.dumps({
                'success': False,
                'error': str(e)
            }).encode())
    
    def log_message(self, format, *args):
        """Custom log message format"""
        sys.stdout.write("[%s] %s - %s\n" %
                        (self.log_date_time_string(),
                         self.address_string(),
                         format % args))

def run_server():
    """Start the HTTP server"""
    server_address = ('', API_PORT)
    # Use ThreadingHTTPServer for concurrent request handling
    httpd = ThreadingHTTPServer(server_address, IRAPIHandler)
    httpd.daemon_threads = True  # Allow threads to exit gracefully
    httpd.timeout = 30  # Socket timeout
    
    print(f"IR Remote Control API Server starting on port {API_PORT}")
    print(f"IR Control Script: {IR_CONTROL_SCRIPT}")
    print(f"Status File: {STATUS_FILE}")
    print("Using threaded server for concurrent requests")
    print("Ready to receive commands...")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()

