# data-commons-workspace

## Docker

### Build

To build the docker image, change to the docker directory and run:

    docker build -t datacommons:latest .

The above command will create an image with an entrypoint into the python virtualenv containing a useful base set of tools for interacting with the platform.  When a container is first created, authentication to the irods filesystem will be performed.  

To build the authentication directly into the image beforehand so it can more quickly be run without re-authenticating each time, run:

    docker build -t datacommons:latest --build-arg IRODS_PASSWORD=<your-password> .

Where <your-password> is the password for the irods user account specified in the irods\_environment section of datacommons\_docker\_setup.centos7.sh

This docker image uses the FUSE module to mount irods, which requires CAP_SYS_ADMIN and access to the fuse device.  These are disabled by docker by default.

### Run

To reenable and run the image with limited permissions:

    docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 8888:8888 -p 8080:8080 --name dc_container datacommons

or run with complete permissions:

    docker run -it --privileged --rm -p 8888:8888 -p 8080:8080 --name dc_container datacommons

This will start up a jupyter notebook instance inside the virtual environment, and attach stdout to the current terminal.  It will also start a wes-server instance in the background.

To run the container and send both the jupyter and wes-server to the background, and attach to a shell in the virtual environment instead, append 'venv' to the end of the docker run command:

    docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 8888:8888 -p 8080:8080 --name dc_container datacommons venv

This command will bind host port 8080 to container port 8080.  This provides host access to the wes-server instance in the container.  If this is not needed, the '-p 8080:8080' option can be omitted.  Note that the wes-client command that is used to send workflows to a wes-server is configured and available in the container.  If host port 8080 is already in use and host access to wes-server is desired, change the first 8080 in the pair to a port not in use.  

Since we specified a container name, we can also attach additional shells to the container in the virtual environment, using that name and the command venv, which is an interactive entrypoint script in the container:

    docker exec -it dc_container venv
