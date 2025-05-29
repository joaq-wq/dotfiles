#!/bin/bash
CITY="Recife"
curl -s "wttr.in/${CITY}?format=%c+%t" | sed 's/ //g'
