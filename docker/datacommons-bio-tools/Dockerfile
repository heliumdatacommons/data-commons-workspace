FROM heliumdatacommons/datacommons-jupyter

RUN sudo yum install -y vim git wget curl gcc gcc-c++ bzip2  bzip2-devel bzip2-libs zlib zlib-devel

COPY ./postinstall.sh ./entrypoint.sh  /home/dockeruser/

RUN sudo chmod +x /home/dockeruser/postinstall.sh \
    && sudo chmod +x /home/dockeruser/entrypoint.sh \
    && touch /home/dockeruser/.profile \
    && bash postinstall.sh

EXPOSE 80 8080 8888

ENTRYPOINT ["bash", "-i", "/home/dockeruser/entrypoint.sh"]
CMD ["venv"]
