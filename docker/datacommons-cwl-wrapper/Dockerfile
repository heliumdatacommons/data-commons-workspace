FROM ubuntu:18.04
# we use bash here
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# install base packages
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get install -y dialog man apt-transport-https apt-utils \
    && apt-get install -y curl vim gnupg lsb-release \
    && apt-get update \
    && apt-get install -y --force-yes sudo iptables nodejs git python-pip python3-pip gcc docker.io nfs-common screen dnsutils htop bmon

COPY ./venv /usr/bin/venv
RUN chmod +x /usr/bin/venv

COPY ./toilvenv /usr/bin/toilvenv
RUN chmod +x /usr/bin/toilvenv

RUN groupadd datacommons \
    && useradd -m dockeruser -g datacommons -G docker -s /bin/bash \
    && echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons

USER dockeruser
WORKDIR /home/dockeruser


RUN sudo apt-get install -y openssh-server \
    && sudo apt-get clean \
    && sudo ssh-keygen -A \
    && mkdir -p ~/.ssh \
    && touch ~/.ssh/authorized_keys \
    && chmod 700 ~/.ssh
RUN pip3 install --user virtualenv \
    && python3.6 -m virtualenv ~/venv \
    && export TOIL_INSTALL=/opt/toil \
    && echo "export TOIL_INSTALL=/opt/toil" >> ~/.profile \
    && cd /opt \
    && sudo git clone https://github.com/heliumdatacommons/toil \
    && sudo chown -R dockeruser:datacommons toil \
    && cd toil \
    #&& git checkout rebase-2018-06-29 \
    && pip2 install virtualenv \
    && python2.7 -m virtualenv venv2.7 \
    && source venv2.7/bin/activate \
    && pip2 install pip==8.1.2 \
    && pip2 install chronos-python \
    && echo 0
RUN cd /opt/toil \
    && git pull \
    && source venv2.7/bin/activate \
    && pip2 install -e .[cwl,mesos,aws] \
    && sudo ln -s /opt/toil/_toil_worker.sh /usr/bin/_toil_worker \
    && sudo git clone https://github.com/heliumdatacommons/schema_salad.git /opt/schema_salad \
    && sudo chown -R dockeruser:datacommons /opt/schema_salad \
    && cd /opt/schema_salad \
    && sed -i "s|version='2.7'|version='2.8'|g" setup.py \
    && pip install . \
    && echo 0

COPY ./cwl_wrapper_postinstall.sh ./dc_toil_setup.sh ./cwl-wrapper-start.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/cwl_wrapper_postinstall.sh \
    && sudo chmod +x /home/dockeruser/dc_toil_setup.sh \
    && sudo chmod +x /home/dockeruser/cwl-wrapper-start.sh

COPY ./entrypoint.sh ./run-cwl.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/entrypoint.sh \
    && sudo chmod +x /home/dockeruser/run-cwl.sh
EXPOSE 80

#COPY ./davrods-vhost.conf /etc/apache2/sites-available/
ENTRYPOINT ["bash", "/home/dockeruser/entrypoint.sh"]
CMD ["/bin/bash", "-i"]
