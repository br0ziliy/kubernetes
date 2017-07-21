#!/bin/bash -x

ANSIBLE_USER='root'
ANSIBLE_HOME='/root'
GITREPO="https://github.com/mtecer/kubernetes.git"

source /etc/profile.d/proxy.sh

cat << HERE > $${ANSIBLE_HOME}/.ssh/id_rsa
${ssh_private_key}
HERE

cat << HERE > $${ANSIBLE_HOME}/.ssh/config
Host *
    ServerAliveInterval 60
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    User $${ANSIBLE_USER}
    IdentityFile $${ANSIBLE_HOME}/.ssh/id_rsa
HERE

chown $${ANSIBLE_USER}.$${ANSIBLE_USER} $${ANSIBLE_HOME}/.ssh/id_rsa
chown $${ANSIBLE_USER}.$${ANSIBLE_USER} $${ANSIBLE_HOME}/.ssh/config

chmod 0400 $${ANSIBLE_HOME}/.ssh/id_rsa
chmod 0400 $${ANSIBLE_HOME}/.ssh/config

if ! rpm -q --quiet git; then
    echo "Installing git"
    yum -y install git
else
    echo "git is already installed"
fi

if [ ! -d $${ANSIBLE_HOME}/ansible ]; then
    echo "Configuring ansible"
    git clone $${GITREPO} $${ANSIBLE_HOME}/ansible
else
    echo "Updating git repo in /ansible"
    cd $${ANSIBLE_HOME}/ansible && git pull
fi

if [ ! -d /ansible ]; then
    ln -s $${ANSIBLE_HOME}/ansible/ansible /ansible
    chown -R $${ANSIBLE_USER}.$${ANSIBLE_USER} $${ANSIBLE_HOME}/ansible
fi

if ! rpm -q --quiet epel-release ansible; then
    echo "Installing ansible"
    rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
    yum -y install epel-release
    yum -y install ansible net-tools bind-utils
else
    echo "Ansible is already installed"
fi

# ln -f -s /home/opc/hosts /ansible/environments/dev/hosts

# cd /ansible
# ansible-galaxy install -r /ansible/requirements.yaml --roles-path /ansible/roles
# # ansible -m ping all
# # ansible-playbook playbook.yaml

# # consul members
# # consul operator raft -list-peers
