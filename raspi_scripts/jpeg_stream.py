#!/usr/bin/env python3

import io
import socket
import struct
import time
import picamera

tcpServer = socket.socket()
tcpServer.bind(('', 50002))
tcpServer.listen(1)

connection = tcpServer.accept()[0].makefile('wb')
try:
        with picamera.PiCamera() as camera:
                camera.resolution = (640, 480)
                camera.framerate = 10
                time.sleep(3)
                for foo in camera.capture_continuous(connection, 'jpeg', use_video_port=True):
                        connection.write(b'19900628\r\n')
finally:
        connection.close()
        tcpServer.close()


"""try:
        with picamera.PiCamera() as camera:
                camera.resolution = (640, 480)
                time.sleep(3)
                while True:
                        camera.capture(connection, 'jpeg', use_video_port=True)
                        connection.write(b'19900628\r\n')
finally:
        connection.close()
        tcpServer.close()"""
		
"""try:
		with picamera.PiCamera() as camera:
				camera.resolution = (640, 480)
				camera.framerate = 30
				time.sleep(3)
				stream = io.BytesIO()
				for foo in camera.capture_continuous(stream, 'jpeg', use_video_port=True):
						stream.seek(0)
						connection.write(stream.read())
						connection.write(b'19900628\r\n')
						stream.seek(0)
						stream.truncate()
finally:
    connection.close()
    tcpServer.close()"""