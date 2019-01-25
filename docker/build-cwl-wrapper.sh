#!/bin/bash
imagename="heliumdatacommons/datacommons-cwl-wrapper"

docker build -t "$imagename" -f ./datacommons-cwl-wrapper/Dockerfile "$@" ./datacommons-cwl-wrapper
