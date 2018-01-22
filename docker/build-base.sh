imagename="heliumdatacommons/datacommons-base"

docker build -t "$imagename" -f ./datacommons-base/Dockerfile.base "$@" ./datacommons-base
