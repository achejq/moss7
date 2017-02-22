#!/bin/bash
if ! grep '^PHP$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist php-fpm
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "PHP FactCGI is running on this host!"
    fi

## handle source packages
    file_proc ${PHP_SRC}
    get_file
    unpack

## fix ldap libs link
    PRE_CONFIG='cp -frp /usr/lib64/libldap* /usr/lib/'

    CONFIG="./configure \
            --prefix=${INST_DIR}/${SRC_DIR} \
            --with-config-file-path=${INST_DIR}/${SRC_DIR}/etc \
            --with-curl \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --with-openssl \
            --with-zlib \
            --with-mcrypt \
            --with-gettext \
            --with-gd \
            --with-jpeg-dir \
            --with-png-dir \
            --with-gettext \
            --with-freetype-dir \
            --with-mhash \
            --with-ldap \
            --with-gmp \
            --with-iconv \
            --with-xmlrpc \
            --with-pcre-regex \
            --without-pear \
            --enable-mysqlnd \
            --enable-fpm \
            --enable-gd-jis-conv \
            --enable-gd-native-ttf \
            --enable-ftp \
            --enable-zip \
            --enable-bcmath \
            --enable-sockets \
            --enable-calendar \
            --enable-soap \
            --enable-shmop \
            --enable-sysvsem \
            --enable-sysvshm \
            --enable-sysvmsg \
            --enable-mbstring \
            --enable-opcache \
            --disable-ipv6 \
            --disable-cgi \
            --disable-phar \
            --disable-rpath"

## fix ldap lber link
    POST_CONFIG='sed -i "/^EXTRA_LIBS =.*$/s//& -llber/" ${STORE_DIR}/${SRC_DIR}/Makefile'

## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/php'
    compile
    
    mkdir ${INST_DIR}/${SRC_DIR}/ext

## for install config files
        succ_msg "Begin to install ${SRC_DIR} config files"
        ## user add
        id www >/dev/null 2>&1 || useradd www -u 1001 -M -s /sbin/nologin -d /www/wwwroot
        ## www dir
        [ ! -d "/www/wwwroot" ] && mkdir -m 0755 -p /www/wwwroot
        ## conf
        install -m 0644 ${TOP_DIR}/conf/php/php.ini ${INST_DIR}/${SRC_DIR}/etc/php.ini
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.conf ${INST_DIR}/${SRC_DIR}/etc/php-fpm.conf
        ## log
        [ ! -d "/var/log/php" ] && mkdir -m 0755 -p /var/log/php
        [ ! -d "/usr/local/etc/logrotate" ] && mkdir -m 0755 -p /usr/local/etc/logrotate
        chown www:www -R /var/log/php
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.logrotate /usr/local/etc/logrotate/php-fpm
        ## cron job
        echo '' >> /var/spool/cron/root
        echo '# Logrotate - PHP-FPM' >> /var/spool/cron/root
        echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/php-fpm > /dev/null 2>&1' >> /var/spool/cron/root
        chown root:root /var/spool/cron/root
        chmod 600 /var/spool/cron/root
        ## opcache
        OPCACHE=$(find ${INST_DIR}/${SRC_DIR}/ -name 'opcache.so')
        mv -f ${OPCACHE} ${INST_DIR}/${SRC_DIR}/ext/ 
        ## security
        #sed -i "s#^open_basedir.*#open_basedir = "${NGX_DOCROOT},/tmp"#" /usr/local/php/etc/php.ini
        ## init scripts
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.service /usr/lib/systemd/system/php-fpm.service
        systemctl daemon-reload
        systemctl enable php-fpm.service
        ## start
        systemctl start php-fpm.service
        sleep 3

## check proc
    proc_exist php-fpm
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "PHP-FPM fail to start!"
    fi

## record installed tag
    echo 'PHP' >> ${INST_LOG}
else
    succ_msg "PHP already installed!"
fi
