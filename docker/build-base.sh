#!/bin/bash
imagename="heliumdatacommons/datacommons-base"

docker build -t "$imagename" -f ./datacommons-base/Dockerfile "$@" ./datacommons-base
