#!/bin/bash

cd /home/pi/diploma

#./soros.py &
sleep 10
./jpeg_stream.py &
sleep 5
./parancskezelo.py &

echo "python scripts are running"