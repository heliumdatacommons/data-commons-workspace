#!/bin/bash

# Install Q
git clone https://github.com/charite/Q.git
echo 'export PATH=$PATH:/home/dockeruser/Q/bin' >> ~/.profile
source ~/.profile
