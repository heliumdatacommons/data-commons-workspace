#!/bin/bash
imagename="heliumdatacommons/datacommons-toil"

docker build -t "$imagename" -f ./datacommons-toil/Dockerfile.toil "$@" ./datacommons-toil
