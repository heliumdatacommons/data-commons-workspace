#!/bin/bash
cd /opt/toil/
source venv2.7/bin/activate
rm -rf /renci/irods/home/kferriter/jobstore*
cwltoil --noLinkImports --jobStore /renci/irods/home/kferriter/jobstore1 --batchSystem chronos --workDir /renci/irods/home/kferriter /renci/irods/home/kferriter/complex-workflow-1.cwl /renci/irods/home/kferriter/complex-workflow-1-job-toil.yml
