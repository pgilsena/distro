#!/usr/bin/env python
import datetime
import logging
import pdb
import socket
import sys
import threading

s_num = 13325655
ALIVE = True
ROOMS = []

class ClientThread(threading.Thread):

    def __init__(self, clientsocket, address):
        logging.error("%s - THREAD: Creating client thread..." % datetime.datetime.now())
        threading.Thread.__init__(self)
        self.conn = clientsocket
        self.address = address
        self.ip = address[0]
        self.port = address[1]
        logging.error("%s - THREAD: Client thread created" % datetime.datetime.now())

    def run(self):
        global ALIVE
        while True:
            data = self.conn.recv(2048)
            if data == 'HELO BASE_TEST\n':
                logging.error('CLIENT: HELO message')
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%d' % ('10.62.0.166', 8008, 13325655)
                self.conn.send(response)
            elif 'ANYTHING' in data:
                logging.error("CLIENT: anything message")
            elif data == 'KILL_SERVICE\n':
                logging.error('CLIENT: kill message')
                ALIVE = False
                self.conn.close()
                return
            elif 'JOIN_CHATROOM' in data:
                logging.error("CLIENT: going to join chatroom")
                self.connectToRoom(data)
            else:
                return
        return

    def connectToRoom(self, data):
        logging.error("Connecting client to room")
        try:
            data = data.splitlines()
            room = data[0].replace('JOIN_CHATROOM: ','')
            ip = data[1].replace('CLIENT_IP: ', '')
            port = data[2].replace('PORT: ', '')
            client_name = data[3].replace('CLIENT_NAME: ', '')

            one = "JOINED_CHATROOM:%s\n" % room
            two = "SERVER_IP:%s\n" % self.ip
            three = "PORT:%d\n" % 0
            four = "ROOM_REF:%d\n" % 0
            five = "JOIN_ID:%s\n" % 0#client_name
            response = one + two + three + four + five
            self.conn.send(response)
        except:
            logging.error("Something wrong with message")
            return

    def check_room_exists(self, room):
        if room in ROOMS:
            return True
        else
            ROOMS.append()


#logging.basicConfig(filename='log.log', filemode='w', level=logging.DEBUG)
my_port = int(sys.argv[1])
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
#server.bind(('localhost', my_port))
server.bind(('10.62.0.166', my_port))

# server.listen(4)
logging.error("%s - SERVER: Listening..." % datetime.datetime.now())
threads = []

while ALIVE == True:
    server.listen(4)
    (clientsocket, address) = server.accept()
    ct = ClientThread(clientsocket, address)
    ct.start()
    threads.append(ct)
    logging.error("%s - SERVER: thread added" % datetime.datetime.now())
    logging.error("THREAD COUNT = %d" % len(threads))

for t in threads:
    t.join()
logging.error("DONE!")