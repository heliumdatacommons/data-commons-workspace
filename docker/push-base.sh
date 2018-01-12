imagename="datacommons-base"
if [ ! -z "$1" ]; then
    imagename="$1"
fi
docker tag "$imagename" heliumdatacommons/datacommons-base:latest
docker push heliumdatacommons/datacommons-base:latest
