imagename="datacommons-jupyter"
if [ ! -z "$1" ]; then
    imagename="$1"
fi
docker tag "$imagename" heliumdatacommons/datacommons-jupyter:latest
docker push heliumdatacommons/datacommons-jupyter:latest
