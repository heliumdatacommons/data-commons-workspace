FROM heliumdatacommons/datacommons-base

COPY sparkmagic.config.json dc_jupyter_setup.sh entrypoint.sh /home/dockeruser/
RUN bash dc_jupyter_setup.sh

COPY cat-workflow.ipynb cat.cwl cat-job.yml  /home/dockeruser/venv/
RUN sudo chown -R dockeruser:datacommons /home/dockeruser/venv/

EXPOSE 8888 8080
ENTRYPOINT ["/bin/bash", "-i", "/home/dockeruser/entrypoint.sh"]
CMD ["jupyter"]
