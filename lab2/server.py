import socket

def main():

	host = "localhost"
	port = 8000

	sock = socket.socket()
	sock.bind((host,port))

	sock.listen(5)
	conn, addr = sock.accept()
	
	while True:
		msg = conn.recv(1024).decode()
		if not msg:
			break
		print ("Client message: " + str(msg))
		msg = msg + "!"
		conn.send(msg.encode())
	conn.close()

if __name__ == '__main__':
	main()

