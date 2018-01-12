imagename="datacommons-jupyter"
if [ ! -z $1 ]; then
    imagename="$1"
fi

docker build -t "$imagename" -f ./datacommons-jupyter/Dockerfile.jupyter "${@:2}" ./datacommons-jupyter
