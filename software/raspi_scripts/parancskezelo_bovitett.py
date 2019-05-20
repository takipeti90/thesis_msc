#!/usr/bin/env python3

import serial
import io
import socket
import time
import select
import os

# Soros port inicializalas
baudr = 115200
tout = 10*(1/baudr)
serial = serial.Serial('/dev/ttyAMA0',baudrate=baudr,timeout=tout)
serial.open()
serData = 0

# UDP inicializalas, server-RPi, client-laptop
laptopIP = "192.168.1.7"
laptopPort = 50000
raspberryPort = 50001
sock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
sock.bind(('',raspberryPort))
sock.setblocking(0)
udpData = 0
portOpen = 1
streaming = 0

serial.write(b'#RP111\r\n')
print("Initialization ready!")

while True:
        # soros porton bejovo adatot UDP-n tovabbitja
        serData = serial.readline()
        if(serData):
                if(serData == b'#RP000\r\n' and portOpen == 1):
                        print("CLOSING PORTS")
                        if(streaming == 1):
                                print("KILL JPEG STREAMING")
                                os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("sudo fuser -k 50002/tcp")
                        if(streaming == 2):
                                print("KILL H264 STREAMING")
                                os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                        sock.close()
                        portOpen = 0
                        streaming = 0
                elif(serData == b'#RP001\r\n' and portOpen == 0):
                        print("OPENING PORTS")
                        sock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
                        sock.bind(('',raspberryPort))
                        sock.setblocking(0)
                        udpData = 0
                        portOpen = 1
                        streaming = 0
                elif(serData == b'#RP002\r\n' and portOpen == 1 and (streaming == 0 or streaming == 2)):
                        if(streaming == 2):
                                print("KILL H264 STREAMING")
                                os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                        print("JPEG STREAMING")
                        os.system("python3 /home/pi/diploma/jpeg_stream.py &")
                        streaming = 1
                elif(serData == b'#RP003\r\n' and portOpen == 1 and (streaming == 0 or streaming == 1)):
                        if(streaming == 1):
                                print("KILL JPEG STREAMING")
                                os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("sudo fuser -k 50002/tcp")
                        print("H264 STREAMING")
                        os.system("/home/pi/diploma/h264_stream.sh")
                        streaming = 2
                elif(serData == b'#RP004\r\n' and portOpen == 1 and streaming == 1):
                        print("KILL JPEG STREAMING")
                        os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                        os.system("sudo fuser -k 50002/tcp")
                        streaming = 0
                elif(serData == b'#RP005\r\n' and portOpen == 1 and streaming == 2):
                        print("KILL H264 STREAMING")
                        os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                        os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                        streaming = 0
                elif(portOpen == 1 and len(serData) == 60):
                        print("SERIAL:")
                        print(serData)
                        sock.sendto(serData, (laptopIP, laptopPort))
                serData = 0

        # UDP-n bejovo adatot soros porton tovabbitja
        if(portOpen == 1):
                ready = select.select([sock], [], [], 0.001)
                if ready[0]:
                        udpData = sock.recv(8)
                if(udpData):
                        if(udpData == b'#RP000\r\n'):
                                print("CLOSING PORTS")
                                if(streaming == 1):
                                        print("KILL JPEG STREAMING")
                                        os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                        os.system("sudo fuser -k 50002/tcp")
                                if(streaming == 2):
                                        print("KILL H264 STREAMING")
                                        os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                        os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                sock.close()
                                portOpen = 0
                                streaming = 0
                        elif(udpData == b'#RP002\r\n' and (streaming == 0 or streaming == 2)):
                                if(streaming == 2):
                                        print("KILL H264 STREAMING")
                                        os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                        os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                print("JPEG STREAMING")
                                os.system("python3 /home/pi/diploma/jpeg_stream.py &")
                                streaming = 1
                        elif(udpData == b'#RP003\r\n' and (streaming == 0 or streaming == 1)):
                                if(streaming == 1):
                                        print("KILL JPEG STREAMING")
                                        os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                        os.system("sudo fuser -k 50002/tcp")
                                print("H264 STREAMING")
                                os.system("/home/pi/diploma/h264_stream.sh")
                                streaming = 2
                        elif(udpData == b'#RP004\r\n' and streaming == 1):
                                print("KILL JPEG STREAMING")
                                os.system("ps aux | grep jpeg_stream.py | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("sudo fuser -k 50002/tcp")
                                streaming = 0
                        elif(udpData == b'#RP005\r\n' and streaming == 2):
                                print("KILL H264 STREAMING")
                                os.system("ps aux | grep 'nc -l -p 5001' | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                os.system("ps aux | grep raspivid | grep -v grep | awk '{print $2}' | xargs sudo kill")
                                streaming = 0
                        elif(udpData != b'#RP002\r\n' and udpData != b'#RP003\r\n' and udpData != b'#RP004\r\n' and udpData != b'#RP005\r\n'):
                                print("UDP:")
                                print(udpData)
                                serial.write(udpData)
                        udpData = 0
sock.close()
serial.close()