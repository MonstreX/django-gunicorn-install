#!/bin/bash
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

project_path=`pwd`
project_domain=""
default_domain=`basename "$project_path"`
centos=`cat /etc/os-release | grep 'CentOS'`

# get domain name
# get domain name
echo -e "${GREEN}Detect default domain: ${BLUE}$default_domain${NC}"
read -p "Press Enter to use default domain or enter other domain name: " project_domain

if [[ -z $project_domain ]]; then
    project_domain=$default_domain
fi

echo -n -e "Uninstall Gunicorn Service and Socket? ${GREEN}(N/y)${NC}? "
read answer
if [ "$answer" == "${answer#[YyДд]}" ] ;then
    exit
fi

echo -e "${BLUE}Uninstalling services...${NC}"
printf %"$(tput cols)"s |tr " " "-"

sudo service nginx stop
sudo systemctl disable gunicorn.${project_domain}.socket
sudo systemctl disable gunicorn.${project_domain}
sudo systemctl stop gunicorn.${project_domain}.socket
sudo systemctl stop gunicorn.${project_domain}

sudo rm .nginx/${project_domain}.conf
sudo rm .gunicorn/gunicorn.${project_domain}.socket
sudo rm .gunicorn/gunicorn.${project_domain}.service
sudo rm /run/gunicorn.${project_domain}.sock

if [[ -z $centos ]]; then
    sudo rm /etc/nginx/sites-enabled/${project_domain}.conf
else
    sudo rm /etc/nginx/conf.d/${project_domain}.conf
fi

sudo service nginx start
sudo systemctl daemon-reload

printf %"$(tput cols)"s |tr " " "-"
echo -e "${BLUE}Done...${NC}"

