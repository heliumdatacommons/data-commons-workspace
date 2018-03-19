#!/bin/bash
imagename="heliumdatacommons/datacommons-jupyter"

docker build -t "$imagename" -f ./datacommons-jupyter/Dockerfile "$@" ./datacommons-jupyter
