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
USERS = []
ROOMS_AND_USERS = []


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

            if self.check_room_exists(room) == False:
                room_pair = self.create_new_room(room)
            user_pair = self.add_new_user(client_name)
            self.add_user_to_room(room_pair, user_pair)
            logging.error("Added user to room")
            pdb.set_trace()

            response = "JOINED_CHATROOM:%s\nSERVER_IP:%s\nPORT:%d\nROOM_REF:%d\nJOIN_ID:%s\n" % room, self.ip, self.ip, room_pair[0], user_pair[1]
            self.conn.send(response)
        except:
            logging.error("Something wrong with message")
            return

    def check_room_exists(self, room):
        tmp = len(ROOMS)
        if tmp > 0:
            for i in range(len(ROOMS)):
                if ROOMS[[i][1]] == room:
                    return True
        else:
            return False

    def create_new_room(self, room_name):
        logging.error("ROOM: Creating new room")
        idx = len(ROOMS)
        ROOMS.append([idx, room_name]) # fix this
        ROOMS_AND_USERS.append([idx, []])
        return [idx, room_name]

    def add_new_user(self, client_name):
        logging.error("USER: Creating new user")
        idx = len(USERS)
        USERS.append([idx, client_name, self.conn]) # fix this
        return [idx, client_name]

    def add_user_to_room(self, room_pair, user_pair):
        if user_pair[0] in ROOMS_AND_USERS[room_pair[0]][1]:
            logging.error("User already in room")
            return
        else:
            logging.error("Adding user to room")
            ROOMS_AND_USERS[room_pair[0]][1].append(user_pair[0])
            #self.conn.send("%s has joined this chatroom\n" % user_pair[1])


    def rename_this():
        while 1:
        socket_list = [sys.stdin, s]

        # Get the list sockets which are readable
        ready_to_read,ready_to_write,in_error = select.select(socket_list , [], [])

        for sock in ready_to_read:
            if sock == s:
                # incoming message from remote server, s
                data = sock.recv(4096)
                if not data :
                    print '\nDisconnected from chat server'
                    sys.exit()
                else :
                    #print data
                    sys.stdout.write(data)
                    sys.stdout.write('[Me] '); sys.stdout.flush()

            else :
                # user entered a message
                msg = sys.stdin.readline()
                s.send(msg)
                sys.stdout.write('[Me] '); sys.stdout.flush()


#logging.basicConfig(filename='log.log', filemode='w', level=logging.DEBUG)
my_port = int(sys.argv[1])
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('localhost', my_port))
# server.bind(('10.62.0.166', my_port))

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

# 'JOIN_CHATROOM: room1\nCLIENT_IP: 0\nPORT: 0\nCLIENT_NAME: client1\n'