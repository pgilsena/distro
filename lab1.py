import socket
 
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
 
host = '10.62.0.166'
port = 8000
s.connect((host , port))

text = "make this caps"
message = "GET /echo.php/?message=%s HTTP/1.1\r\n\r\n" % text 
s.sendall(message)
response = s.recv(1046)

print response
s.close()