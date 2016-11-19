import logging
import pdb
import socket
import sys
import threading

s_num = 13325655
threads = []

class ThreadedServer(object):
    global threads

    def __init__(self, ip, port):
        logging.info("Creating new thread...")
        self.ip = ip
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((self.ip, self.port))
        # logging.info("Server socket created")

    def serverListen(self):
        self.sock.listen(5)
        logging.info("Listening...")

        while True:
            conn, address = self.sock.accept()
            newthread = threading.Thread(self.clientListen(conn, address))
            newthread.start()
            threads.append(newthread)
            #logging.info(" newthread started: %d") % len(threads)

    def clientListen(self, conn, address):
        size = 1024
        while True:
            msg = conn.recv(size)
            if msg != 'KILL_SERVICE\n':
                # logging.info("Message: %s" % msg)
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%s' % (self.ip, self.port, S_NUM)
                conn.send(response)
            else:
                logging.info("Message: %s" % msg)
                self.close_everything()
                return

    def close_everything(self):
        # pdb.set_trace()
        for t in threads:
            t.join()
        self.sock.close()
        logging.info("Everything closed")
        sys.exit()

if __name__ == "__main__":
    logging.basicConfig(filename='lab2.log',level=logging.DEBUG)
    port = int(sys.argv[1])
    ThreadedServer('10.62.0.166', port).serverListen()
