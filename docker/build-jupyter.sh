imagename="heliumdatacommons/datacommons-jupyter"

docker build -t "$imagename" -f ./datacommons-jupyter/Dockerfile.jupyter "$@" ./datacommons-jupyter
