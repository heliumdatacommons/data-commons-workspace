FROM centos:centos7

# add irods repo
RUN rpm --import https://packages.irods.org/irods-signing-key.asc \
        && curl https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo \
    && yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm \
    && yum update -y \
    && yum install -y \
        sudo python36u python36u-devel fuse gcc git nodejs \
    && yum install -y \
        ftp://ftp.renci.org/pub/irods/releases/4.1.11/centos7/irods-runtime-4.1.11-centos7-x86_64.rpm \
        ftp://ftp.renci.org/pub/irods/releases/4.1.11/centos7/irods-icommands-4.1.11-centos7-x86_64.rpm \
    && yum install -y \
        https://github.com/UtrechtUniversity/davrods/releases/download/4.1_1.2.0/davrods-4.1_1.2.0-1.el7.centos.x86_64.rpm \
    && yum clean all

COPY ./venv /usr/bin/venv
RUN chmod +x /usr/bin/venv

RUN groupadd datacommons \
    && useradd -m dockeruser -g datacommons -s /bin/bash \
    && echo "dockeruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/datacommons

USER dockeruser
WORKDIR /home/dockeruser

RUN sudo yum install -y emacs-nox

COPY ./base_postinstall.sh ./entrypoint.sh  /home/dockeruser/
RUN sudo chmod +x /home/dockeruser/base_postinstall.sh \
    && sudo chmod +x /home/dockeruser/entrypoint.sh \
    && touch /home/dockeruser/.profile \
    && bash base_postinstall.sh

EXPOSE 80

COPY ./davrods-vhost.conf /etc/httpd/conf.d/
ENTRYPOINT ["bash", "-i", "/home/dockeruser/entrypoint.sh"]
CMD ["venv"]