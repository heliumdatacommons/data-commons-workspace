export TOIL_INSTALL=/opt/toil
echo "export TOIL_INSTALL=${TOIL_INSTALL}" >> ~/.profile

cd /opt
sudo git clone https://github.com/theferrit32/toil
sudo chown -R dockeruser:datacommons toil
cd toil
./install.sh

sudo yum clean all
