#!/bin/bash
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

project_path=`pwd`
default_domain=`basename "$project_path"`
project_name="main"
base_python_interpreter=`which python3`
username=$USER
group="www-data"
django_manage=./manage.py

# manage.py check and get main django folder
if [ -f "$django_manage" ]; then
    project_name=`grep 'DJANGO_SETTINGS_MODULE' $django_manage | grep -Po "(?<=(DJANGO_SETTINGS_MODULE', ')).*(?=.settings)"`
else
    echo -e "Error: ${BLUE}$django_manage${NC} ${RED}not found${NC} in the current folder. You should start the script from root django project folder"
    exit
fi

# get domain name
read -p "Your domain without protocol (example.com) or press Enter to use $default_domain: " project_domain

if [[ -z $project_domain ]]; then
    project_domain=$default_domain
fi

# Make VENV if not present
if [[ ! -d ./.venv ]]; then
    echo '.venv folder not found. Creating venv...'
    `$base_python_interpreter -m venv .venv`
fi
source .venv/bin/activate

# install Gunicorn
if [ -f ./poetry.lock ]; then
    echo 'Poetry installed. Using Poetry manager...'
    poetry install
    poetry add gunicorn
else
    echo 'Using PiP manager'
    pip install -U pip
    pip install -r requirements.txt    
    pip install gunicorn
fi

# install Gunicorn
if [ -f ./poetry.lock ]; then
    echo 'Poetry installed. Using Poetry manager...'
    poetry add gunicorn
else
    echo 'Use PiP'
    pip install gunicorn
fi

# Prepare and config main server configs
echo -e "${GREEN}Creating service and nginx config files...${NC}"
cp .nginx/conf.template .nginx/${project_domain}.conf
cp .gunicorn/gunicorn.service.template .gunicorn/gunicorn.${project_domain}.service
cp .gunicorn/gunicorn.socket.template .gunicorn/gunicorn.${project_domain}.socket

sed -i "s~%domain%~$project_domain~g" .nginx/${project_domain}.conf .gunicorn/gunicorn.${project_domain}.service .gunicorn/gunicorn.${project_domain}.socket
sed -i "s~%project_path%~$project_path~g" .nginx/${project_domain}.conf .gunicorn/gunicorn.${project_domain}.service .gunicorn/gunicorn.${project_domain}.socket

sed -i "s~%username%~$username~g" .gunicorn/gunicorn.${project_domain}.service
sed -i "s~%group%~$group~g" .gunicorn/gunicorn.${project_domain}.service
sed -i "s~%project_name%~$project_name~g" .gunicorn/gunicorn.${project_domain}.service

# Making links
sudo ln -s ${project_path}/.nginx/${project_domain}.conf /etc/nginx/sites-enabled/${project_domain}.conf
sudo ln -s ${project_path}/.gunicorn/gunicorn.${project_domain}.service /etc/systemd/system/
sudo ln -s ${project_path}/.gunicorn/gunicorn.${project_domain}.socket /etc/systemd/system/

echo -e "${GREEN}Reloading daemon, nginx and start gunicorn service...${NC}"

sudo systemctl start gunicorn.${project_domain}.socket
sudo systemctl enable gunicorn.${project_domain}.socket
sudo systemctl daemon-reload
sudo systemctl restart gunicorn.${project_domain}
sudo systemctl reload nginx

echo -e "${BLUE}Done...${NC}"
