import socket
 
def main():
		host = 'localhost'
		port = 8000
		
		s = socket.socket()
		s.connect((host,port))
		
		message = input("Message: ")
		
		while message != 'q':
				s.send(message.encode())
				data = s.recv(1024).decode()
				
				print ('Received from server: ' + data)
				message = input("Message: ")
		s.close()
 
if __name__ == '__main__':
	main()

