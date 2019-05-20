#!/bin/bash

raspivid -w 640 -h 480 -t 0 -fps 20 -b 5000000 -o - | nc -l -p 5001 &

echo "streaming .h264 video"