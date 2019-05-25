#!/bin/bash
# this actually just makes a zip file
./build_spritesheets.sh

zip -r kanabaltti.love \
    main.lua \
    conf.lua \
    libs \
    systems \
    assets/LuckiestGuy-Regular.ttf \
    assets/sprites/spritesheet.png \
    assets/sprites/spritesheet.json
