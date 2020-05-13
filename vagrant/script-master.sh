#!/bin/bash

# Instaladores:
function installDocker(){

    apt install docker.io -y
    usermod -aG docker $USER
    systemctl enable docker
}

function installKubernetes(){

    apt install software-properties-common curl -y
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
    apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
    apt install kubeadm -y
}

function installBind9(){

    apt install bind9 -y
    systemctl enable bind9
}

function installLAMP(){

    apt install lamp-server^ -y
}

# Configuradores

function configBind9(){

    mkdir /etc/bind/zonas
    echo -e 'zone "rock.com"{
    type master;
    file "/etc/bind/zonas/rock.db";
};' > /etc/bind/named.conf.local
    
    echo -e "\$TTL    604800
@   IN  SOA rock.com. root.rock.com. (
                   2
              604800
               86400
             2419200
              604800 )
;
@   IN  NS  rock.com.
*   IN  A   192.168.1.5
@   IN  A   192.168.1.5
*   IN  A   192.168.1.6
*   IN  A   192.168.1.7" > /etc/bind/zonas/rock.db

    echo -e 'options {
    directory "/var/cache/bind";
    forwarders {
        8.8.8.8;
    };
    dnssec-validation auto;
    auth-nxdomain no;
    listen-on-v6 { any; };
};' > /etc/bind/named.conf.options

    service bind9 restart
}

function configMysql(){

    echo -e "CREATE DATABASE therockproject;
CREATE USER 'dev'@'localhost' IDENTIFIED BY 'dev';
GRANT ALL PRIVILEGES ON therockproject.* TO 'dev'@'localhost';" > script.sql
    mysql < script.sql
    rm script.sql
}

function configApache(){

    echo -e "<VirtualHost *:80>
    DocumentRoot /var/www/html
    ErrorDocument 404 /404.html
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

    rm /var/www/html/index.html
    git clone https://github.com/Alopezfu/therockproject.git
    cp -r therockproject/admin/* /var/www/html
    mysql < /var/www/html/DDBB.sql
    chown www-data:www-data /var/www/html -R
    chmod 755 /var/www/html -R
    rm -rf therockproject
}

function main(){

    apt update
    apt upgrade -y
    installDocker
    installKubernetes
    installBind9
    installLAMP

    configBind9
    configApache
    configMysql
}

main