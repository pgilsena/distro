#!/usr/bin/env python
import datetime
import logging
import pdb
import socket
import sys
import threading

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
        tmp = len(USERS)
        self.join_id = len(USERS)


class Room():
    def __init__(self, name):
        self.name = name
        self.ref = 0
        self.usrs = []

    def updateRef(self):
        global ROOMS
        idx = len(ROOMS)
        self.ref = idx
        #self.ref = ROOMS[tmp].ref + 1#idx
        ROOMS.append(self)

    def deleteRoom():
        # TODO: remove room
        return

    def populateRoom(self, usr):
        logging.error('USER: adding %s to %s' % (usr.name, self.name))
        self.usrs.append(usr)
        return

    def removeUser(self, usr):
    	print self.usrs
    	logging.error('Removing user %s from %s' % (usr.name, self.name))
        for client in self.usrs:
            if client.name == usr.name:
                self.usrs.remove(client)
                logging.error("User has been removed")
                print self.usrs
                break

    def sendMessageToRoom(self, msg):
        logging.error("Sending message to %s" % self.name)
        logging.error("Message is: %s" % msg)
        for client in self.usrs:
            if client.name != self.name:
                client.conn.send(msg)
                logging.error("Sent message to: %s" % client.name)
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
            logging.error("RECEIVED MESSAGE: %s" % data)
            if data == 'HELO BASE_TEST\n':
                response = 'HELO BASE_TEST\nIP:%s\nPort:%d\nStudentID:%d' % ('10.62.0.166', 8008, 13325655)
                self.conn.send(response)
            elif 'JOIN_CHATROOM' in data:
                self.joinMessage(data, client_created)
                client_created = True # check this
            elif 'LEAVE' in data:
                self.leaveMessage(data)
            elif 'CHAT' in data:
                self.chatMessage(data)
            elif 'KILL_SERVICE' in data:
                self.closeEverything()
                return
            else:
            	logging.error("Unrecognised message or empty")
            	return
        return


    def closeEverything(self):
        logging.info("Received message to kill a thread")
        return

    def breakdownMessage(self, data):
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
            self.usr.updateUser(msg[3])

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
        room.populateRoom(self.usr)
        response = "JOINED_CHATROOM:%s\nSERVER_IP:%s\nPORT:%d\nROOM_REF:%d\nJOIN_ID:%d\n" % (room.name, self.ip, self.port, room.ref, self.usr.join_id)
        self.conn.send(response)
        msg_group = "CHAT:%d\nCLIENT_NAME:%s\nMESSAGE:%s has joined this chatroom.\n\n" % (room.ref, self.usr.name, self.usr.name)
        logging.error("Possible chat message")
        room.sendMessageToRoom(msg_group)

    def chatMessage(self, data):
        data = data.splitlines()
        room = data[0].replace('CHAT: ','')
        join_id = data[1].replace('JOIN_ID: ', '')
        client_name = data[2].replace('CLIENT_NAME: ', '')
        message = data[3].replace('MESSAGE: ', '')
        
        for roomIdx in ROOMS:
            if str(roomIdx.ref) == room:
                room2 = roomIdx
                pdb.set_trace()
                roomIdx.sendMessageToRoom(message)
                break

		logging.error("message sent")
        return

    def leaveMessage(self, data):
        global ROOMS
        try:
            data = data.splitlines()
            roomRef = data[0].replace('LEAVE_CHATROOM: ','')
            join_id = data[1].replace('JOIN_ID: ', '')
            client_name = data[2].replace('CLIENT_NAME: ', '')
            for roomIdx in ROOMS:
                if str(roomIdx.ref) == roomRef:
                    room = roomIdx
                    break
            self.conn.send("LEFT_CHATROOM:%d\nJOIN_ID:%d\n" % (room.ref, self.usr.join_id))
            leave2 = "CHAT:%d\nCLIENT_NAME:%s\nMESSAGE:%s has left this chatroom.\n\n" % (room.ref, self.usr.name, self.usr.name)
            room.sendMessageToRoom(leave2)
            room.removeUser(self.usr)
            self.rooms.remove(room)
        except:
            logging.error("Something wrong with exit message")
            return
        return

    def doesRoomExist(self, name):
        global ROOMS
        tmp = len(ROOMS)
        if tmp > 0:
            for room in ROOMS:
                if room.name == name:
                    logging.error("Room %s already exists" % room.name)
                    return True
        else:
            return False
        return

my_port = int(sys.argv[1])
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('134.226.32.10', my_port))
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