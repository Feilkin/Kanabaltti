#!/bin/bash
rm -f assets/sprites/spritesheet.png assets/sprites/spritesheet.json
/home/feikki/aseprite/build/bin/aseprite -b assets/sprites/*.aseprite --sheet-pack --border-padding 1 --shape-padding 1 --scale 2 --sheet assets/sprites/spritesheet.png  --list-tags --data assets/sprites/spritesheet.json --format json-array