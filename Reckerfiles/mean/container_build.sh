#!/bin/bash

# some basic settings for CentOS
echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
/bin/rm /etc/localtime
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo '[[ "${PS1-}" ]] && PS1=":D $PS1"' >> /etc/bashrc

# Write here how to build container
USERNAME='localadm'

# prerequisites
yum -y install \
    rsyslog cronie tar bzip2 \
    which curl wget w3m telnet sudo perl \
    openssh openssh-server openssh-clients git \
    libpng-devel fontconfig

# mongodb
cat <<'_EOF_' > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
_EOF_
yum -y install mongodb-org
cat <<'_EOF_' >> /etc/mongod.conf
journal=true
smallfiles=true
_EOF_

# Node.js grunt gulp bower mean
yum -y install epel-release
perl -07 -pi \
    -e 's/(\[epel\].*?enabled *)= *1/$1=0/is;' \
    /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install nodejs npm
yum -y install icu libicu-devel

echo 'export NODE_PATH=$HOME/.npm:/usr/lib/node_modules${NODE_PATH:+:}${NODE_PATH-}' \
    >> /etc/bashrc

npm install -g bower gulp grunt-cli mean-cli forever
npm install -g imagemin-gifsicle
npm install -g yo generator-angular-fullstack

# sshd setup
service sshd start
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

# make a user
useradd -G wheel $USERNAME
mkdir /home/$USERNAME/.ssh
chmod 0700 /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
chmod 0600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME.$USERNAME /home/$USERNAME/.ssh
echo '%wheel        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
