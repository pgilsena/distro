import socket
import pdb
import threading
import sys

S_NUM = 13325655

class MyThread(threading.Thread):

    def __init__(self,ip,port):
        threading.Thread.__init__(self)
        self.ip = ip
        self.port = port

    def run(self):
       while True:
            msg = conn.recv(2048)
            if msg != 'KILL_SERVICE\n':
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%s' % (my_ip, my_port, S_NUM)
                conn.send(response)
            else:
                print "should be breaking here"
                tcpServer.close()
                break

my_ip = '10.62.0.166'
my_port =  int(sys.argv[1])

tcpServer = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
tcpServer.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
tcpServer.bind((my_ip, my_port))
threads = []

while True:
    tcpServer.listen(4)
    (conn, (ip,port)) = tcpServer.accept()
    newthread = MyThread(ip,port)
    newthread.start()
    threads.append(newthread)

tcpServer.close()
conn.close()

for t in threads:
    t.join()