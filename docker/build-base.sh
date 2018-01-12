imagename="datacommons-base"
if [ ! -z $1 ]; then
    imagename="$1"
fi

docker build -t "$imagename" -f ./datacommons-base/Dockerfile.base "${@:2}" ./datacommons-base
