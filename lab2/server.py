import socket
import threading


class ClientThread(threading.Thread):

    def __init__(self, ip, port):
        threading.Thread.__init__(self)
        self.ip = ip
        self.port = port
        print "Message source: %s:%s" % (ip, str(port))

    def run(self):
        while True:
            data = conn.recv(2048)
            print "Server received data:", data
            MESSAGE = raw_input("Message response: ")
            if MESSAGE == 'exit':
                break
            conn.send(MESSAGE)

host = 'localhost'
port = 8000

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((host, port))
threads = []

while True:
    s.listen(5)
    (conn, (ip, port)) = s.accept()
    newthread = ClientThread(ip, port)
    newthread.start()
    threads.append(newthread)

for t in threads:
    t.join()
