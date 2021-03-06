#!/bin/bash
rm -f assets/sprites/spritesheet.png assets/sprites/spritesheet.json
/home/feikki/aseprite/build/bin/aseprite -b src/assets/sprites/*.aseprite \
    --sheet-pack \
    --filename-format "{title}-{frame}" \
    --border-padding 2 \
    --shape-padding 2 \
    --scale 2 \
    --sheet src/assets/sprites/spritesheet.png \
    --list-tags \
    --data src/assets/sprites/spritesheet.json \
    --format json-array

