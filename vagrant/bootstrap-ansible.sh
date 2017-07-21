#!/bin/bash

GITREPO="https://github.com/mtecer/${1}.git"

if ! rpm -q --quiet epel-release ansible; then
    echo "Installing ansible"
    rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
    yum -y install epel-release
    yum -y install ansible git net-tools wget unzip
else
    echo "Ansible is already installed"
fi

if [ ! -d /home/vagrant/ansible ]; then
    echo "Configuring ansible"
    git clone ${GITREPO} /home/vagrant/ansible
else
    echo "Updating git repo in /home/vagrant/ansible"
    cd /home/vagrant/ansible && git pull
fi

if [ ! -d /ansible ]; then
    ln -s /home/vagrant/ansible/ansible /ansible
    chown -R vagrant.vagrant /home/vagrant/ansible
fi