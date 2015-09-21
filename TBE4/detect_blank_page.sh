#!/bin/bash

for i in "$@"; do
    #echo "Processing file: ${i}..."
    if [[ -e $(dirname "$i")/.$(basename "$i") ]]; then
        #echo "   protected."
        continue
    fi

    histogram=$(/usr/local/bin/convert "${i}" -threshold 50% -format %c histogram:info:-)
    #echo $histogram
    white=$(echo "${histogram}" | grep "white" | cut -d: -f1)
    black=$(echo "${histogram}" | grep "black" | cut -d: -f1)
    if [[ -z "$black" ]]; then
        black=0
    fi

    # 0.005 works for the most part.  trying another setting now...
    blank=$(echo "scale=4; ${black}/${white} < 0.0003" | bc)
    #echo "Detected White: ${white}  |  Black: ${black}  |  Blank: ${blank}"
    if [ "${blank}" -eq "1" ]; then
        #echo "Page ${i} seems to be blank - removing it..."
        #mv "${i}" "/tmp/blanks/${i}"
        #mv "${i}" "/tmp/blank-page.jpg"

        echo "blank"
    fi
done
