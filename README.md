# data-commons-workspace

## Docker

To build the docker image, change to the docker directory and run:

    docker build -t datacommons:latest .

The above command will create an image with an entrypoint into the python virtualenv containing a useful base set of tools for interacting with the platform.  When a container is first created, authentication to the irods filesystem will be performed.  

To build the authentication directly into the image beforehand so it can more quickly be run without re-authenticating each time, run:

    docker build -t datacommons:latest --build-args IRODS_PASSWORD=<your-password> .

Where <your-password> is the password for the irods user account specified in the irods\_environment section of datacommons\_docker\_setup.centos7.sh
