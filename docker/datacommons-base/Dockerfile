FROM centos:latest

# add irods repo
RUN rpm --import https://packages.irods.org/irods-signing-key.asc \
        && curl https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo \
    # IUS let their TLS cert expire on May 8, 2018, 7:59 PM
    && curl -O --insecure --location https://centos7.iuscommunity.org/ius-release.rpm \
    && yum install -y epel-release ius-release.rpm \
    && yum update -y \
    && yum install -y \
        sudo python36u python36u-devel davfs2 gcc git nodejs \
    && yum clean all

#COPY ./irods-patched-install.sh /rootd
#RUN bash /root/irods-patched-install.sh



###################################################################################################
###################################################################################################
# build patched irods
RUN yum install -y git sudo which make pam-devel unixODBC unixODBC-devel

# irods build dependencies
ENV IRODS_EXTERNALS="/opt/irods-externals"
RUN git clone https://github.com/irods/externals ${IRODS_EXTERNALS}-src \
    && cd ${IRODS_EXTERNALS}-src \
    # use pre-built packages, but still install the prereqs
    && rpm --import https://packages.irods.org/irods-signing-key.asc \
    && curl -s https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo \
    && yum install -y \
        irods-externals-zeromq4-14.1.3-0 \
        irods-externals-libarchive3.3.2-0 \
        irods-externals-jansson2.7-0 \
        irods-externals-cppzmq4.1-0 \
        irods-externals-clang-runtime3.8-0 \
        irods-externals-clang3.8-0 \
        irods-externals-cmake3.5.2-0 \
        irods-externals-avro1.7.7-0 \
        irods-externals-boost1.60.0-0 \
    && ./install_prerequisites.py

ENV PATH="${IRODS_EXTERNALS}/cmake3.5.2-0/bin:${PATH}"

# build irods from fork
# TODO when 4.2.3 is released, update to that version
ENV IRODS="/opt/irods"
RUN git clone https://github.com/theferrit32/irods ${IRODS} \
    && cd ${IRODS} \
    && git submodule update --init \
    && git checkout 4-2-stable \
    && mkdir build \
    && cd build \
    && cmake -DIRODS_EXTERNALS_PACKAGE_ROOT=${IRODS_EXTERNALS} .. \
    && make -j$(nproc) package \
    # install irods development and library package (dependency of irods-icommands package)
    && yum install -y irods-devel-4.2.3* irods-runtime-4.2.3*

# build irods icommands
ENV IRODS_CLIENT_ICOMMANDS="/opt/irods_client_icommands"
RUN git clone https://github.com/irods/irods_client_icommands ${IRODS_CLIENT_ICOMMANDS} \
    && cd ${IRODS_CLIENT_ICOMMANDS} \
    && git checkout 4-2-stable \
    #sed -i 's|IRODS 4.2.3 EXACT|IRODS 4.2.2 EXACT|g' CMakeLists.txt
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) package \
    && yum install -y irods-icommands-4.2.3*

# install irods oidc auth plugin
ENV IRODS_OIDC="/opt/irods_auth_plugin_openid"
RUN git clone https://github.com/irods-contrib/irods_auth_plugin_openid ${IRODS_OIDC} \
    && cd ${IRODS_OIDC} \
    # Try incrementing version to 4.2.3
    && sed -i 's|IRODS 4.2.2 EXACT|IRODS 4.2.3 EXACT|g' CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) package \
    && yum install -y irods-auth-plugin-openid*

# install davrods from source
RUN yum install -y httpd-devel \
    && git clone https://github.com/UtrechtUniversity/davrods.git \
    && cd davrods \
    && sed -i 's|IRODSRT_VERSION "4.2.2"|IRODSRT_VERSION "4.2.3"|g' CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make package \
    && rpm -i davrods-4.2.3*
###################################################################################################
###################################################################################################



COPY ./venv /usr/bin/venv
RUN chmod +x /usr/bin/venv

COPY ./toilvenv /usr/bin/toilvenv
RUN chmod +x /usr/bin/toilvenv

RUN groupadd datacommons \
    && useradd -m dockeruser -g datacommons -s /bin/bash \
    && echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons

USER dockeruser
WORKDIR /home/dockeruser

COPY ./base_postinstall.sh ./dc_toil_setup.sh ./base-start.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/base_postinstall.sh \
    && sudo chmod +x /home/dockeruser/dc_toil_setup.sh \
    && sudo chmod +x /home/dockeruser/base-start.sh \
    && touch /home/dockeruser/.profile \
    && bash dc_toil_setup.sh \
    && bash base_postinstall.sh

COPY ./entrypoint.sh /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/entrypoint.sh
EXPOSE 80

COPY ./davrods-vhost.conf /etc/httpd/conf.d/
ENTRYPOINT ["bash", "-i", "/home/dockeruser/base-start.sh"]
CMD ["venv"]
