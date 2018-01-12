imagename="datacommons-toil"
if [ ! -z $1 ]; then
    imagename="$1"
fi

docker build -t "$imagename" -f ./datacommons-toil/Dockerfile.toil "${@:2}" ./datacommons-toil
