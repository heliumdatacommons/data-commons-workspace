FROM centos:centos7
ARG IRODS_PASSWORD=""

RUN yum install -y sudo
RUN groupadd datacommons
RUN useradd -m dockeruser -g datacommons -s /bin/bash
RUN echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons
USER dockeruser
WORKDIR /home/dockeruser



COPY datacommons_docker_setup.centos7.sh /home/dockeruser/datacommons_docker_setup.centos7.sh
RUN bash datacommons_docker_setup.centos7.sh

#RUN echo "source ~/entrypoint.sh" >> ~/.bashrc

COPY ./entrypoint.sh /home/dockeruser/entrypoint.sh
RUN sudo chmod 444 /home/dockeruser/entrypoint.sh

CMD ["/bin/bash", "--rcfile", "/home/dockeruser/entrypoint.sh", "-i"]
