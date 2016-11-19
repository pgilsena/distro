#!/usr/bin/env python
import logging
import socket
import sys
import threading

s_num = 13325655

class ThreadedServer(object):
    threads = []

    def __init__(self, ip, port):
        logging.info("Creating server socket...")
        self.ip = ip
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((self.ip, self.port))
        logging.info("Server socket created")

    def serverListen(self):
        self.sock.listen(5)
        logging.info("Listening...")
        try:
            conn, address = self.sock.accept()
            newthread = threading.Thread(self.clientListen(conn, address))
            logging.info("Created new thread")
            newthread.start()
            logging.info("New thread has started")
            threads.append(newthread)
        except:
            logging.info("Server no longer running")
            return
        return

    def clientListen(self, conn, address):
        size = 1024
        while True:
            msg = conn.recv(size)
            if msg != 'KILL_SERVICE\n':
                logging.info("Message: %s" % msg[:-1])
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%s' % (self.ip, self.port, s_num)
                conn.send(response)
            else:
                logging.info("Message: %s" % msg[:-1])
                self.closeEverything()
                return

    def closeEverything(self):
        for t in threads:
            t.join()
        logging.info("Joined all threads")
        self.sock.close()
        logging.info("Closed server")
        return


if __name__ == "__main__":
    logging.basicConfig(filename='lab2.log', filemode='w', level=logging.DEBUG)
    port = int(sys.argv[1])
    ThreadedServer('10.62.0.166', port).serverListen()
