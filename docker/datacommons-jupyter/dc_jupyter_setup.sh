echo "export WES_API_HOST=localhost:8080" >> ~/.bashrc
echo "export WES_API_PROTO=http" >> ~/.bashrc

export VENV=~/venv
cd $VENV
source bin/activate
pip install jupyter

# installing wes-service fork in python3 env
git clone https://github.com/stevencox/workflow-service.git
cd workflow-service && pip install .; cd $VENV


sudo yum install -y krb5-devel
sudo yum clean all
pip install sparkmagic
set -x
jupyter nbextension enable --py --sys-prefix widgetsnbextension
sparkmagic_path=$(pip show sparkmagic | grep -i location | sed -e "s,.*: ,,")
cd $sparkmagic_path
jupyter-kernelspec install sparkmagic/kernels/sparkkernel --user
jupyter-kernelspec install sparkmagic/kernels/pysparkkernel --user
jupyter-kernelspec install sparkmagic/kernels/pyspark3kernel --user
jupyter-kernelspec install sparkmagic/kernels/sparkrkernel --user
mkdir /home/dockeruser/.sparkmagic
cp /home/dockeruser/sparkmagic.config.json /home/dockeruser/.sparkmagic/config.json
