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


class User():
    def __init__(self, name, conn):
        self.name = name
        self.conn = conn
        self.join_id = 0

    def updateUser(self, name):
        global USERS
        self.name = name
        self.join_id = len(USERS)

    def deleteUser():
        # TODO
        return


class Room():
    def __init__(self, name):
        self.name = name
        self.ref = 0
        self.usrs = []

    def updateRef(self):
        global ROOMS
        idx = len(ROOMS)
        self.ref = idx
        ROOMS.append(self)

    def deleteRoom():
        # TODO: remove room
        return

    def populateRoom(self, usr):
        self.usrs.append(usr)
        return

    def removeUser(self, usr):
        for client in self.usrs:
            if client == usr.name:
                del self.usr(client)
                break

    def existsRoom():
        tmp = len(ROOMS)
        if tmp > 0:
            for i in range(len(ROOMS)):
                if ROOMS[[i][1]] == room:
                    return True
        else:
            return False

    def getRoomMembers():
        # TODO: return a list of users in room
        return

    def sendMessageToRoom(self, msg):
        for client in self.usrs:
            client.conn.send(msg)
            #self.conn.send(response)
        return


class ClientThread(threading.Thread):

    def __init__(self, clientsocket, address):
        global USERS

        logging.error("%s - THREAD: Creating client thread..." % datetime.datetime.now())
        threading.Thread.__init__(self)
        self.conn = clientsocket
        self.address = address
        self.ip = address[0]
        self.port = address[1]
        self.usr = User('tempName',self.conn)
        self.rooms = []
        USERS.append(self.usr)
        logging.error("%s - THREAD: Client thread created" % datetime.datetime.now())

    def run(self):
        global ALIVE
        client_created = False

        while True:
            data = self.conn.recv(2048)
            if data == 'HELO BASE_TEST\n':
                logging.error('CLIENT: HELO message')
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%d' % ('10.62.0.166', 8008, 13325655)
                self.conn.send(response)
            elif 'JOIN_CHATROOM' in data:
                logging.error("CLIENT: going to join chatroom")
                room = self.joinMessage(data, client_created)
                client_created = True
            elif 'LEAVE' in data:
                self.leaveMessage(data)
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

    def joinMessage(self, data, client_created):
        msg = self.breakdownMessage(data)
        # Client exists?
        if client_created == False:
            logging.error("USER: doesn't exists, create new user")
            self.usr.updateUser(msg[3]) # create user but will need to allow the change of name

        # Room exists?
        if self.doesRoomExist(msg[0]) == True:
            for roomIdx in ROOMS:
                if roomIdx.name == msg[0]:
                    room = roomIdx
        else:
            logging.error("ROOM: doesn't exist, creating new room")
            room = Room(msg[0])
            room.updateRef()

        self.rooms.append(room)
        # Add user to room
        room.populateRoom(self.usr)
        response = "JOINED_CHATROOM:%s\nSERVER_IP:%s\nPORT:%d\nROOM_REF:%d\nJOIN_ID:%d\n" % (room.name, self.ip, self.port, room.ref, self.usr.join_id)
        self.conn.send(response)
        msg_group = "CHAT:%d\nCLIENT_NAME:%s\nMESSAGE:%s has joined this chatroom.\n" % (room.ref, self.usr.name, self.usr.name)
        room.sendMessageToRoom(msg_group)
        return room

    def leaveMessage(self, data):
        global ROOMS
        try:
            data = data.splitlines()
            room = data[0].replace('LEAVE_CHATROOM: ','')
            join_id = data[1].replace('JOIN_ID: ', '')
            client_name = data[3].replace('CLIENT_NAME: ', '')
            for roomIdx in ROOMS:
                if roomIdx.name == room:
                    room = roomIdx
                    break
            room.removeUser(room)
        except:
            logging.error("Something wrong with message")
            return
        return

    def doesRoomExist(self, name):
        global ROOMS

        tmp = len(ROOMS)
        if tmp > 0:
            for i in range(len(ROOMS)):
                if ROOMS[[i][1]] == room:
                    return True
        else:
            return False
        return

#logging.basicConfig(filename='log.log', filemode='w', level=logging.DEBUG)
my_port = int(sys.argv[1])
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
# server.bind(('localhost', my_port))
server.bind(('10.62.0.166', my_port))

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