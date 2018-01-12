imagename="datacommons-toil"
if [ ! -z "$1" ]; then
    imagename="$1"
fi
docker tag "$imagename" heliumdatacommons/datacommons-toil:latest
docker push heliumdatacommons/datacommons-toil:latest
