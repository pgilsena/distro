#!/usr/bin/env python
import datetime
import logging
import pdb
import socket
import sys
import threading

s_num = 13325655
ALIVE = True
ROOMS = [] # list of Room objects?
USERS = [] #
ROOMS_AND_USERS = []


class User():
    def __init__(self, name, conn):
        self.name = name
        self.conn = conn

    def getUserPair(self, name=None, ref=None):
        return

    def createUser(self, client_name):
        global USERS

        logging.error("USER: Creating new user")
        idx = len(USERS)
        USERS.append([idx, client_name, self.conn]) # fix this
        return [idx, client_name]

    def deleteUser():
        # TODO
        return


class Room():
    def __init__(self, ref, name):
        self.ref = ref
        self.name = name

    def createRoom():
        logging.error("ROOM: Creating new room")
        idx = len(ROOMS)
        ROOMS.append([idx, room_name]) # fix this
        ROOMS_AND_USERS.append([idx, []])
        return [idx, room_name]

    def deleteRoom():
        # TODO: remove room
        return

    def populateRoom():
        if user_pair[0] in ROOMS_AND_USERS[room_pair[0]][1]:
            logging.error("User already in room")
            return
        else:
            logging.error("Adding user to room")
            ROOMS_AND_USERS[room_pair[0]][1].append(user_pair[0])
        return

    def existsRoom():
        tmp = len(ROOMS)
        if tmp > 0:
            for i in range(len(ROOMS)):
                if ROOMS[[i][1]] == room:
                    return True
        else:
            return False
        return

    def getRoomMembers():
        # TODO: return a list of users in room
        return

    def sendMessageToRoom():
        return.


class ClientThread(threading.Thread):

    def __init__(self, clientsocket, address):
        logging.error("%s - THREAD: Creating client thread..." % datetime.datetime.now())
        threading.Thread.__init__(self)
        self.conn = clientsocket
        self.address = address
        self.ip = address[0]
        self.port = address[1]
        self.userName = ''
        self.userRef = 0
        logging.error("%s - THREAD: Client thread created" % datetime.datetime.now())

    def run(self):
        usr = User.createUser('tempName') # create user but will need to allow the change of name
        rooms = []
        global ALIVE
        while True:
            data = self.conn.recv(2048)
            if data == 'HELO BASE_TEST\n':
                logging.error('CLIENT: HELO message')
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%d' % ('10.62.0.166', 8008, 13325655)
                self.conn.send(response)
            elif 'JOIN_CHATROOM' in data:
                logging.error("CLIENT: going to join chatroom")
                msg = self.breakdownMessage(data)
                usr.createUser(msg[3])
                # update User name to be msg[3]

                # check if msg[0] (room) exists
                #   else create the room
                # then add user to room
                # send user the response below
                response = "JOINED_CHATROOM:%s\nSERVER_IP:%s\nPORT:%d\nROOM_REF:%d\nJOIN_ID:%s\n" % room, self.ip, self.ip, room_pair[0], user_pair[1]
                self.conn.send(response)
            elif 'CHAT' in data:
                # TODO: ogging.error('CLIENT: kill message')
                ALIVE = False
                self.conn.close()
                return
            elif 'DISCONNECT' in data:
                # TODO
                return
            else:
                return
        return

    def breakdownMessage(self, data):
        logging.error("Connecting client to room")
        try:
            data = data.splitlines()
            room = data[0].replace('JOIN_CHATROOM: ','')
            ip = data[1].replace('CLIENT_IP: ', '')
            port = data[2].replace('PORT: ', '')
            client_name = data[3].replace('CLIENT_NAME: ', '')
            return [room, ip, port, client_name]
        except:
            logging.error("Something wrong with message")
            return

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