FROM ubuntu:16.04
# we use bash here
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# install base packages
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get install -y dialog man apt-transport-https apt-utils \
    && apt-get install -y curl vim gnupg lsb-release \
    && curl -q https://packages.irods.org/irods-signing-key.asc | apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list \
    && apt-get update \
    && apt-get install -y --force-yes sudo iptables nodejs git python-pip python3-pip gcc docker.io ninja-build davfs2 nfs-common screen dnsutils htop bmon


###################################################################################################
###################################################################################################
# build patched irods

# irods build dependencies
# use pre-built packages, but still install the prereqs, for later builds
ENV IRODS_EXTERNALS="/opt/irods-externals"
RUN git clone https://github.com/irods/externals ${IRODS_EXTERNALS}-src \
    && cd ${IRODS_EXTERNALS}-src \
    && apt-get install -y \
        irods-externals-zeromq4-14.1.6-0 \
        irods-externals-libarchive3.3.2-1 \
        irods-externals-jansson2.7-0 \
        irods-externals-cppzmq4.2.3-0 \
        irods-externals-clang-runtime3.8-0 \
        irods-externals-clang3.8-0 \
        irods-externals-cmake3.11.4-0 \
        irods-externals-avro1.8.2-0 \
        irods-externals-boost1.67.0-0 \
    && ./install_prerequisites.py \
    # these don't seem to be on the dep tree for irods-dev
    && apt install -y libkrb5-dev libzmqpp-dev 

ENV PATH="${IRODS_EXTERNALS}/cmake3.11.4-0/bin:${PATH}"
# build irods from fork
# TODO when 4.2.3 is released, update to that version
#ENV IRODS="/opt/irods"
#RUN git clone https://github.com/theferrit32/irods ${IRODS} \
#    && cd ${IRODS} \
#    && git submodule update --init \
#    && git checkout 4-2-3-dev \
#    && mkdir build \
#    && cd build \
#    && cmake -DIRODS_EXTERNALS_PACKAGE_ROOT=${IRODS_EXTERNALS} .. \
#    && make -j6 package \
#    && apt-get install -y ./irods-devel-4.2.3* ./irods-runtime-4.2.3* \
#    && echo 0
RUN apt install -y irods-dev irods-runtime

# build irods icommands
ENV IRODS_CLIENT_ICOMMANDS="/opt/irods_client_icommands"
RUN git clone https://github.com/heliumdatacommons/irods_client_icommands ${IRODS_CLIENT_ICOMMANDS} \
    && cd ${IRODS_CLIENT_ICOMMANDS} \
    && git checkout 4-2-stable \
    #&& sed -i "s|IRODS 4.2.4|IRODS 4.2.3|g" CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake -G Ninja .. \
    && ninja package \
    && apt-get install -y ./irods-icommands* \
    && echo 0

# install irods oidc auth plugin
ENV IRODS_OIDC="/opt/irods_auth_plugin_openid"
RUN git clone https://github.com/irods-contrib/irods_auth_plugin_openid ${IRODS_OIDC} \
    && cd ${IRODS_OIDC} \
    && sed -i "s|IRODS 4.2.3|IRODS 4.2.4|g" CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake -G Ninja .. \
    && ninja package \
    && apt-get install -y ./irods-auth-plugin-openid* \
    && echo 0

# TODO remove if unneeded
# install irods fuse from source
ENV IRODS_FUSE="/opt/irods_client_fuse"
RUN apt-get install -y fuse libfuse-dev \
    && git clone https://github.com/irods/irods_client_fuse ${IRODS_FUSE} \
    && cd ${IRODS_FUSE} \
    && mkdir build \
    && cd build \
    && cmake -G Ninja .. \
    && ninja package \
    && apt-get install -y ./irods-fuse-*

# install davrods from source
ENV IRODS_DAVRODS="/opt/davrods"
RUN apt-get install -y apache2 apache2-dev
RUN git clone https://github.com/theferrit32/davrods.git ${IRODS_DAVRODS} \
    && cd ${IRODS_DAVRODS} \
    #&& git checkout dev \
    && sed -i 's|IRODSRT_VERSION "4.2.3"|IRODSRT_VERSION "4.2.4"|g' CMakeLists.txt \
    && mkdir build \
    && cd build \
    # davrods doesn't build with ninja
    && cmake .. \
    && make -j2 package \
    && apt-get install -y ./davrods-*

###################################################################################################
###################################################################################################


COPY ./venv /usr/bin/venv
RUN chmod +x /usr/bin/venv

COPY ./toilvenv /usr/bin/toilvenv
RUN chmod +x /usr/bin/toilvenv

RUN groupadd datacommons \
    && useradd -m dockeruser -g datacommons -G docker -s /bin/bash \
    && echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons

USER dockeruser
WORKDIR /home/dockeruser


RUN touch /home/dockeruser/.profile \
    && if [ ! -d ~/.irods ]; then mkdir ~/.irods; fi \
    # set global httpd ServerName to localhost
    && echo "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf \
    # set user/group for davfs
    && sudo sed -i 's|^# dav_user.*|dav_user davfs2|g' /etc/davfs2/davfs2.conf \
    && sudo sed -i 's|^# dav_group.*|dav_group davfs2|g' /etc/davfs2/davfs2.conf \
    && sudo sed -i 's|^# dir_refresh.*|dir_refresh 3|g' /etc/davfs2/davfs2.conf \
    && sudo sed -i 's|^# file_refresh.*|file_refresh 1|g' /etc/davfs2/davfs2.conf \
    && sudo sed -i 's|^# delay_upload.*|delay_upload 0|g' /etc/davfs2/davfs2.conf
ENV IRODS_MOUNT="/renci/irods"
RUN if [ ! -d ${IRODS_MOUNT} ]; then \
        sudo mkdir -p ${IRODS_MOUNT}; \
        sudo chown "${user}:${group}" $IRODS_MOUNT; \
    fi; \
    if grep IRODS_MOUNT ~/.profile; then \
        sed -i "s|^export IRODS_MOUNT=.*$|export IRODS_MOUNT=${IRODS_MOUNT}|g" ~/.profile; \
    else \
        echo "export IRODS_MOUNT=${IRODS_MOUNT}" >> ~/.profile; \
    fi; \
    # set up python 3 virtualenv
    pip3 install --user virtualenv \
    && python3.5 -m virtualenv ~/venv \
    && export TOIL_INSTALL=/opt/toil \
    && echo "export TOIL_INSTALL=/opt/toil" >> ~/.profile \
    && cd /opt \
    && sudo git clone https://github.com/heliumdatacommons/toil \
    && sudo chown -R dockeruser:datacommons toil \
    && cd toil \
    #&& git checkout rebase-2018-06-29 \
    && pip2 install virtualenv \
    && python2.7 -m virtualenv venv2.7 \
    && echo 0
RUN echo "ACTIVATING VENV2.7" \
    && cd /opt/toil && source venv2.7/bin/activate \
    && pip2 install pip==8.1.2 \
    && pip2 install chronos-python \
    # fix @ symbol bug
    #&& pip2 install cwltool \
    && git clone https://github.com/heliumdatacommons/schema_salad.git \
    && cd schema_salad \
    && sed -i "s|version='2.7'|version='2.8'|g" setup.py \
    && pip install .
RUN cd /opt/toil \
    && source venv2.7/bin/activate \
    && pip2 install -e .[cwl,mesos,aws] \
    && sudo ln -s /opt/toil/_toil_worker.sh /usr/bin/_toil_worker \
    && echo 2

# TODO used for updating code without long rebuild
#RUN cd /opt/toil/ && source venv2.7/bin/activate \
#    && git pull && pip install -e .[cwl,mesos,aws] \
#    && echo 0

RUN sudo apt-get install -y openssh-server \
    && sudo apt-get clean \
    && sudo ssh-keygen -A \
    && mkdir -p ~/.ssh \
    && touch ~/.ssh/authorized_keys \
    && chmod 700 ~/.ssh

# TODO remove
RUN cd /opt/davrods \
    && sudo git pull \
    && cd build \
    && sudo make package \
    && sudo dpkg -i ./davrods-*

COPY ./base_postinstall.sh ./dc_toil_setup.sh ./base-start.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/base_postinstall.sh \
    && sudo chmod +x /home/dockeruser/dc_toil_setup.sh \
    && sudo chmod +x /home/dockeruser/base-start.sh

COPY ./entrypoint.sh ./run-cwl.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/entrypoint.sh \
    && sudo chmod +x /home/dockeruser/run-cwl.sh
EXPOSE 80

COPY ./davrods-vhost.conf /etc/apache2/sites-available/
ENTRYPOINT ["bash", "/home/dockeruser/base-start.sh"]
CMD ["venv"]
