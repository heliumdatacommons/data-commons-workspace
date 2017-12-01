# data-commons-workspace

## Docker

To build the docker image, change to the docker directory and run:

    docker build -t datacommons:latest .

The above command will create an image with an entrypoint into the python virtualenv containing a useful base set of tools for interacting with the platform.  When a container is first created, authentication to the irods filesystem will be performed.  

To build the authentication directly into the image beforehand so it can more quickly be run without re-authenticating each time, run:

    docker build -t datacommons:latest --build-arg IRODS_PASSWORD=<your-password> .

Where <your-password> is the password for the irods user account specified in the irods\_environment section of datacommons\_docker\_setup.centos7.sh

This docker image uses the FUSE module to mount irods, which requires CAP_SYS_ADMIN and access to the fuse device.  These are disabled by docker by default.

To reenable and run the image with limited permissions:

    docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 8888:8888 datacommons

or run with complete permissions:

    docker run -it --privileged --rm -p 8888:8888 datacommons

This will start up a jupyter notebook instance inside the virtual environment, and attach stdout to the current terminal.

To attach a new shell to the container in the virtualenvironment, get the container id with:

    docker ps -a

And run:

    docker exec -it <container-id> venv

