#!/bin/bash
# this actually just makes calls love-release
./build_spritesheets.sh
love-release -W 32 -W 64 -a Feilkin -t Kanabaltti release src