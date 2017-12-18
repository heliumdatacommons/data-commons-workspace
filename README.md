# data-commons-workspace


## Build

There are multiple images created with this repository. To build then change to the docker directory. The build*.sh scripts contain the step to create a properly tagged image that corresponds to the image in Docker Hub:

To build the base image with irods and webdav and cwltool:

    bash build-base.sh

To build the datacommons-jupyter image, build the base image first then

    bash build-jupyter.sh

The above command will create an image with an entrypoint into the python virtualenv containing a useful base set of tools for interacting with the platform.  When a container is first created, authentication to the irods filesystem will be performed.  

This image uses the [davrods](https://github.com/UtrechtUniversity/davrods) webdav implementation to provide a browsable webdav interface on port 80 of the container, which can be forwarded to the host.  If host port 80 is in use, use another like 90.

This docker image uses the FUSE module to mount irods, which requires CAP_SYS_ADMIN and access to the fuse device.  These are disabled by docker by default.

## Run

### Base image

To reenable and run the base image with that allows for connecting to the WebDav irods interface on host port 90:

    docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 90:80 --name dc_base datacommons-base


### Jupyter image

   docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 8888:8888 -p 8080:8080 -p 90:80 --name dc_jupyter datacommons-jupyter

This will start up a jupyter notebook instance inside the virtual environment, and attach stdout to the current terminal.  It will also start a wes-server instance in the background available on host port 8080, and davrods (webdav) on host port 90.  The jupyter notebook is available on host port 8888.

If the wes-server is not needed from the host, the '-p 8080:8080' can be ommited.  Note that the wes-client command that is used to send workflows to a wes-server is configured and available in the container.  If host port 8080 is already in use and host access to wes-server is desired, change the first 8080 in the pair to a port not in use.  

To run the container and send both the jupyter and wes-server to the background, and attach to a shell in the virtual environment instead, append 'venv' to the end of the docker run command:

    docker run -it --cap-add=SYS_ADMIN --device=/dev/fuse --rm -p 8888:8888 -p 8080:8080 -p 90:80 --name dc_container datacommons-jupyter venv

Since we specified a container name, we can also attach additional shells to the container in the virtual environment, using that name and the command 'venv', which is an interactive entrypoint script in the container:

    docker exec -it dc_container venv
