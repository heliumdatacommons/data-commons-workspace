FROM centos:centos7
ARG IRODS_PASSWORD=""

RUN yum install -y sudo

COPY ./venv /usr/bin/venv
RUN sudo chmod +x /usr/bin/venv

RUN groupadd datacommons
RUN useradd -m dockeruser -g datacommons -s /bin/bash
RUN echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons
USER dockeruser
WORKDIR /home/dockeruser

COPY ./entrypoint.sh /home/dockeruser/entrypoint.sh
RUN sudo chmod 444 /home/dockeruser/entrypoint.sh

EXPOSE 8888

COPY sparkmagic.config.json /home/dockeruser/sparkmagic.config.json
COPY datacommons_docker_setup.centos7.sh /home/dockeruser/datacommons_docker_setup.centos7.sh
RUN bash datacommons_docker_setup.centos7.sh

COPY cat-workflow.ipynb /home/dockeruser/venv/cat-workflow.ipynb
COPY cat.cwl /home/dockeruser/venv
COPY cat-job.yml /home/dockeruser/venv
RUN sudo chown -R dockeruser:datacommons /home/dockeruser/venv

ENTRYPOINT ["/bin/bash", "-i", "/home/dockeruser/entrypoint.sh"]
#CMD ["/home/dockeruser/entrypoint.sh"]
