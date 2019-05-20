#!/bin/bash

while true ; do
        if ifconfig wlan0 | grep -q "inet addr:" ; then
                if iwlist wlan0 scan | grep "RPi" ; then
                        echo "RPi network connected"
                fi
                echo "Wi-Fi network connected."
                sleep 30
        else
                echo "Network connection down! Attempting reconnection."
                #if iwlist wlan0 scan | grep "RPi" ; then
                #       echo "RPi network detected."
                        sudo ifup --force wlan0
                #       ifconfig wlan0 | grep "inet addr"
                #fi
                sleep 10
        fi
done
