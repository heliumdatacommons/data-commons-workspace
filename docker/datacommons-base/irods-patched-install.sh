###################################################################################################
###################################################################################################
# build patched irods
yum install -y git sudo which make pam-devel unixODBC unixODBC-devel

# irods build dependencies
export IRODS_EXTERNALS=/opt/irods-externals
git clone https://github.com/irods/externals ${IRODS_EXTERNALS}-src
cd ${IRODS_EXTERNALS}-src
# use pre-built packages, but still install the prereqs
#make package
rpm --import https://packages.irods.org/irods-signing-key.asc
curl -s https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo
yum install -y \
    irods-externals-zeromq4-14.1.3-0 \
    irods-externals-libarchive3.3.2-0 \
    irods-externals-jansson2.7-0 \
    irods-externals-cppzmq4.1-0 \
    irods-externals-clang-runtime3.8-0 \
    irods-externals-clang3.8-0 \
    irods-externals-cmake3.5.2-0 \
    irods-externals-avro1.7.7-0 \
    irods-externals-boost1.60.0-0
./install_prerequisites.py

export PATH=$IRODS_EXTERNALS/cmake3.5.2-0/bin:$PATH

# build irods from fork
# TODO when 4.2.3 is released, update to that version
export IRODS=/opt/irods
git clone https://github.com/theferrit32/irods $IRODS
cd $IRODS
git submodule update --init
git checkout 4-2-stable
mkdir build
cd build
cmake -DIRODS_EXTERNALS_PACKAGE_ROOT=$IRODS_EXTERNALS ..
make -j$(nproc) package

# install irods development and library package (dependency of irods-icommands package)
yum install -y irods-dev* irods-runtime*

# build irods icommands
export IRODS_CLIENT_ICOMMANDS=/opt/irods_client_icommands
git clone https://github.com/irods/irods_client_icommands $IRODS_CLIENT_ICOMMANDS
cd $IRODS_CLIENT_ICOMMANDS
git checkout 4-2-stable
#sed -i 's|IRODS 4.2.3 EXACT|IRODS 4.2.2 EXACT|g' CMakeLists.txt
mkdir build
cd build
cmake ..
make -j$(nproc) package
yum install -y irods-icommands*

# install irods oidc auth plugin
export IRODS_OIDC=/opt/irods_auth_plugin_openid
git clone https://github.com/irods-contrib/irods_auth_plugin_openid $IRODS_OIDC
cd $IRODS_OIDC
# Try incrementing version to 4.2.3
sed -i 's|IRODS 4.2.2 EXACT|IRODS 4.2.3 EXACT|g' CMakeLists.txt
mkdir build
cd build
cmake ..
make -j$(nproc) package
yum install -y irods-auth-plugin-openid*

# install davrods from source
yum install -y httpd-devel
git clone https://github.com/UtrechtUniversity/davrods.git
cd davrods
sed -i 's|IRODSRT_VERSION "4.2.2"|IRODSRT_VERSION "4.2.3"|g' CMakeLists.txt
mkdir build
cd build
cmake ..
make package
rpm -i davrods-4.2.3*
###################################################################################################
###################################################################################################

