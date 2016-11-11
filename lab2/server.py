import socket
import threading

S_NUM = 13325655

class Server(object):
    def __init__(self, host, port):
        self.host = '10.62.0.166'
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.bind((self.host, self.port))

    def listen(self):
        self.sock.listen(5)
        while True:
            client, addr = self.sock.accept()
            threading.Thread(self.listenToClient(client,addr)).start()
        self.sock.close()

    def listenToClient(self, client, addr):
        size = 1024
        while True:
            msg = client.recv(size)
            if msg != 'KILL_SERVICE':
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%s' % (self.host, self.port, S_NUM)
                client.send(response)
            else:
                client.close()
                return False

if __name__ == "__main__":
    Server('localhost',8001).listen()
