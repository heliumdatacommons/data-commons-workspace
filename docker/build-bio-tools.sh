#!/bin/bash
imagename="heliumdatacommons/bio-tools"

docker build -t "$imagename" -f ./datacommons-bio-tools/Dockerfile "$@" ./datacommons-bio-tools
