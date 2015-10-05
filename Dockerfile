# Superduper dockerfile to manage php application!

FROM jedisct1/phusion-baseimage-latest:latest
MAINTAINER Yoan Blanc <yoan@dosimple.ch>

# Ports
EXPOSE 22
EXPOSE 80

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# NodeSource special setup (does the apt-get update already, twice)
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -

RUN apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ack-grep \
    build-essential \
    cowsay \
    curl \
    fortunes \
    fortunes-fr \
    fontconfig \
    git \
    libxrender1 \
    man \
    mariadb-client \
    mercurial \
    nano \
    nginx \
    nodejs \
    php5-cli \
    php5-curl \
    php5-fpm \
    php5-imagick \
    php5-mcrypt \
    php5-mysql \
    php5-xdebug \
    pwgen \
    python3-pip \
    python3-jinja2 \
    python3-software-properties \
    screen \
    ssmtp \
    subversion \
    sudo \
    tmux \
    toilet \
    unzip \
    vim \
    wget \
    xfonts-base \
    xfonts-75dpi

# wkhtmltopdf/wkhtmltoimage
RUN wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb -O /tmp/wkhtmltox.deb
RUN dpkg -i /tmp/wkhtmltox.deb

# Locale
RUN locale-gen fr_CH
RUN locale-gen fr_CH.UTF-8
RUN locale-gen de_CH
RUN locale-gen de_CH.UTF-8
RUN locale-gen it_CH
RUN locale-gen it_CH.UTF-8
RUN update-locale LANG=fr_CH.UTF-8 LC_MESSAGES=POSIX

# Node.js stuff.
RUN npm install -g \
    gulp \
    grunt-cli \
    yo

# Composer
RUN curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable SSHD
RUN rm -f /etc/service/sshd/down
# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

## Nginx
RUN rm /etc/nginx/sites-enabled/default
RUN rm -r /var/www/html
# only one worker process and no daemonize
RUN sed -i 's/\(worker_processes\) .;/\1 1;\ndaemon off;/' /etc/nginx/nginx.conf

## PHP ini
RUN sed -i 's/;\(date.timezone =\).*/\1 "Europe\/Zurich"/' /etc/php5/fpm/php.ini
RUN sed -i 's/\(error_reporting =\).*/\1 E_ALL/' /etc/php5/fpm/php.ini
RUN sed -i 's/\(display_errors =\).*/\1 On/' /etc/php5/fpm/php.ini
RUN sed -i 's/;\(cgi.fix_pathinfo=\).*/\1 0/' /etc/php5/fpm/php.ini

RUN sed -i 's/;\(date.timezone =\).*/\1 "Europe\/Zurich"/' /etc/php5/cli/php.ini
RUN sed -i 's/\(error_reporting =\).*/\1 E_ALL/' /etc/php5/cli/php.ini
RUN sed -i 's/\(display_errors =\).*/\1 On/' /etc/php5/cli/php.ini
RUN sed -i 's/;\(cgi.fix_pathinfo=\).*/\1 0/' /etc/php5/cli/php.ini

## MYSQL client
RUN set -i 's/utf8/utf8mb4/' /etc/mysql/mariadb.conf.d/client.conf

## Runit
ADD scripts/runit/nginx /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
ADD scripts/runit/nginx-log-forwarder /etc/service/nginx-log-forwarder/run
RUN chmod +x /etc/service/nginx-log-forwarder/run
ADD scripts/runit/php5-fpm /etc/service/php5-fpm/run
RUN chmod +x /etc/service/php5-fpm/run

#
# SUDO for any user
#
RUN echo '%users ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/users
RUN chmod 0440 /etc/sudoers.d/users

# Enable screen
RUN chmod 0775 /var/run/screen

# Files
ADD files/templates /tmp/templates
# Composer / Laravel
ADD files/composer /tmp/.composer
# Vundle
ADD files/vundle /tmp/Vundle.vim

# Expose VOLUME
VOLUME /root/config
VOLUME /var/www

# Config
ENV GROUPNAME unknown
ENV MYSQL_DATABASE test
ENV MYSQL_USERNAME test
ENV MYSQL_PASSWORD test

# Init.d
ADD scripts/30_setup.py /etc/my_init.d/30_setup.py
RUN chmod +x /etc/my_init.d/30_setup.py
