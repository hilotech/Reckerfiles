#!/bin/bash

# some basic settings for CentOS
echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
/bin/rm /etc/localtime
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo '[[ "${PS1-}" ]] && PS1=":D $PS1"' >> /etc/bashrc

# Write here how to build container
USERNAME='localadm'

# prerequisites
yum -y groupinstall 'Development tools'
yum -y install \
    rsyslog cronie tar bzip2 which curl wget sudo perl \
    openssh openssh-server openssh-clients git \
    httpd httpd-devel \
    mysql mysql-devel mysql-server mysql-libs \
    libxml2-devel bison bison-devel openssl-devel curl-devel \
    libjpeg-devel libpng-devel readline-devel \
    libtidy-devel libxslt-devel libevent libevent-devel \
    libtool-ltdl libtool-ltdl-devel
yum -y install epel-release
perl -07 -pi \
    -e 's/(\[epel\].*?enabled *)= *1/$1=0/is;' \
    /etc/yum.repos.d/epel.repo
yum --enablerepo=epel -y install \
    re2c \
    libmcrypt libmcrypt-devel

# httpd
sed -i \
    -e 's|^\(DirectoryIndex[[:blank:]]\{1,\}\)\(index.html index.html.var\)|\1index.php \2|' \
    -e 's|^\([[:blank:]]\{0,\}Options[[:blank:]]\{0,\}.*\)Indexes\([[:blank:]]\{1,\}.*\)$|\1\2|' \
    /etc/httpd/conf/httpd.conf
cat <<'_EOF_' > /etc/httpd/conf.d/servernname.conf
ServerName localhost
_EOF_
perl -07 -p -i \
    -e 's|(<Directory "/var/www/html">.*?\s+AllowOverride\s+)None|$1 All|is;' \
    /etc/httpd/conf/httpd.conf
cat <<'_EOF_' > /etc/httpd/conf.d/php-ext.conf
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps
_EOF_
cat <<'_EOF_' >> /var/www/html/phpinfo.php
<?php
    phpinfo();
?>
_EOF_
chmod g+s /var/www/html
chown -R apache.apache /var/www/html
chmod -R g+w /var/www/html
cat <<'_EOF_' >> /usr/bin/change-document-root
#!/bin/sh
if [[ -z "${1-}" ]]; then
    echo 'specify document root' >&2
    exit 1
fi
sed -i -e "s|^\(DocumentRoot \).*$|\1 $1|" /etc/httpd/conf/httpd.conf
_EOF_
chmod +x /usr/bin/change-document-root

# installing phpenv, php-build, phpenv-apache-version
tempDir=`mktemp -d`
cd $tempDir
git clone https://github.com/CHH/phpenv.git
PHPENV_ROOT=/usr/local/phpenv phpenv/bin/phpenv-install.sh
cat <<'_EOF_' >> /etc/bashrc

export PATH="/usr/local/phpenv/bin:$PATH"
eval "$(phpenv init -)"
_EOF_
export PATH="/usr/local/phpenv/bin:$PATH"
eval "$(phpenv init -)"
cd /tmp
/bin/rm -r "${tempDir-}"
git clone https://github.com/php-build/php-build.git \
    /usr/local/phpenv/plugins/php-build
git clone https://github.com/garamon/phpenv-apache-version \
    /usr/local/phpenv/plugins/phpenv-apache-version
/usr/local/phpenv/plugins/php-build/install.sh
REPLACE=$(\
    cat <<'_EOF_'
        if [ -f "$TMP/source/$DEFINITION/libs/libphp5.so" ]; then
            cp "$TMP/source/$DEFINITION/libs/libphp5.so" \
                "$PREFIX"
        fi
_EOF_
) \
perl -07 -pi \
    -e 's|(make install\n)(\s+make clean)|$1$ENV{REPLACE}\n$2|is;' \
    /usr/local/phpenv/plugins/php-build/bin/php-build
fn=/usr/local/phpenv/plugins/php-build/share/php-build/default_configure_options
cat <<'_EOF_' >> ${fn-}
--with-apxs2=/usr/sbin/apxs
_EOF_
# because of https://bugs.php.net/bug.php?id=52419
sed -i -e '/--enable-fpm/d' ${fn-}
fn=/usr/local/share/php-build/default_configure_options
cat <<'_EOF_' >> ${fn-}
--with-apxs2=/usr/sbin/apxs
_EOF_
sed -i -e '/--enable-fpm/d' ${fn-}
phpenv install 5.6.9
phpenv install 5.3.3
phpenv global 5.6.9
phpenv apache-version 5.6.9

# installing Laravel prerequisites
tempDir=`mktemp -d`
cd $tempDir
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
cd /tmp
/bin/rm -r "${tempDir-}"

# mysql setup
service mysqld start

# sshd setup
service sshd start
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

# make a user
useradd -G wheel,apache $USERNAME
mkdir /home/$USERNAME/.ssh
chmod 0700 /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
chmod 0600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME.$USERNAME /home/$USERNAME/.ssh
echo '%wheel        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
