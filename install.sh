#!/bin/bash
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

project_path=`pwd`
django_path=$project_path
venv_path=${$project_path}/.env
default_domain=`basename "$project_path"`
project_name="main"
base_python_interpreter=`which python3`
username=$USER

print_result()
{
    printf %"$(tput cols)"s |tr " " "-"
    echo -e "${GREEN}Testing created socket connection: ${NC} ${1}" 
    printf %"$(tput cols)"s |tr " " "-"
    echo -e "${2}"
}

printf %"$(tput cols)"s |tr " " "-"
echo -e "${BLUE}Django Gunicorn Installation:${NC}"
printf %"$(tput cols)"s |tr " " "-"

# find root Django project path
for folder in `find . -type d -name "*"`
do
   if [ -f ${folder}/pyvenv.cfg ]; then
       venv_path=${project_path}/${folder:2}
       break
   fi
done

# find venv path
if [ ! -f manage.py ]; then
    for folder in `find . -type d -name "*"`
    do
       if [ -f ${folder}/manage.py ]; then
           django_path=${django_path}/${folder:2}
           break
       fi
    done
fi

# check for Cent OS and set specific nginx group 
centos=`cat /etc/os-release | grep 'CentOS'`
if [[ -z $centos ]]; then
  group="www-data"
else
  group="nginx"
fi

# manage.py check and get main django folder
if [ -f ${django_path}/manage.py ]; then
    project_name=`grep 'DJANGO_SETTINGS_MODULE' ${django_path}/manage.py | grep -Po "(?<=(DJANGO_SETTINGS_MODULE', ')).*(?=.settings)"`
else
    echo -e "Error: ${BLUE}manage.py${NC} ${RED}not found${NC} in the project folders and subfolders."
    exit
fi

# get custom domain name
echo -e "${GREEN}Detect default domain: ${BLUE}$default_domain${NC}"
read -p "Press Enter to use default domain or enter other domain name: " project_domain

if [[ -z $project_domain ]]; then
    project_domain=$default_domain
fi

echo -e "${BLUE}Start installation...${NC}"
printf %"$(tput cols)"s |tr " " "-"

# create VENV if not present
if [[ ! -f ${venv_path}/pyvenv.cfg ]]; then
    echo 'venv folder not found. Creating .venv...'
    `$base_python_interpreter -m venv .venv`
    venv_path=${project_path}/.venv
fi

source ${venv_path}/bin/activate

# install Gunicorn
if [ -f ./poetry.lock ]; then
    echo 'Poetry installed. Using Poetry manager...'
    poetry install
    poetry add gunicorn
else
    echo 'Using PiP manager'
    if [ -f ./requirements.txt ]; then
        pip3 install -U pip
        pip3 install -r requirements.txt
    fi
    pip3 install gunicorn
fi

# Prepare and config main server configs
echo -e "${GREEN}Creating service and nginx config files...${NC}"
cp .nginx/conf.template .nginx/${project_domain}.conf
cp .gunicorn/gunicorn.service.template .gunicorn/gunicorn.${project_domain}.service
cp .gunicorn/gunicorn.socket.template .gunicorn/gunicorn.${project_domain}.socket

sed -i "s~%domain%~$project_domain~g" .nginx/${project_domain}.conf .gunicorn/gunicorn.${project_domain}.service .gunicorn/gunicorn.${project_domain}.socket
sed -i "s~%project_path%~$project_path~g" .nginx/${project_domain}.conf .gunicorn/gunicorn.${project_domain}.service .gunicorn/gunicorn.${project_domain}.socket
sed -i "s~%venv_path%~$venv_path~g" .gunicorn/gunicorn.${project_domain}.service
sed -i "s~%django_path%~$django_path~g" .nginx/${project_domain}.conf .gunicorn/gunicorn.${project_domain}.service

sed -i "s~%username%~$username~g" .gunicorn/gunicorn.${project_domain}.service
sed -i "s~%group%~$group~g" .gunicorn/gunicorn.${project_domain}.service
sed -i "s~%project_name%~$project_name~g" .gunicorn/gunicorn.${project_domain}.service

# Making links
if [[ -z $centos ]]; then
  sudo ln -s ${project_path}/.nginx/${project_domain}.conf /etc/nginx/sites-enabled/${project_domain}.conf
else
  sudo ln -s ${project_path}/.nginx/${project_domain}.conf /etc/nginx/conf.d/${project_domain}.conf
fi  
sudo ln -s ${project_path}/.gunicorn/gunicorn.${project_domain}.service /etc/systemd/system/
sudo ln -s ${project_path}/.gunicorn/gunicorn.${project_domain}.socket /etc/systemd/system/

echo -e "${GREEN}Reloading daemon, nginx and start gunicorn service...${NC}"

sudo systemctl start gunicorn.${project_domain}.socket
sudo systemctl enable gunicorn.${project_domain}.socket
sudo systemctl daemon-reload
sudo systemctl restart gunicorn.${project_domain}
sudo systemctl reload nginx

# Socket test
sock_response=`curl --unix-socket /run/gunicorn.${project_domain}.sock localhost`

if [[ ! -z $sock_response ]]; then
    print_result ${GREEN}Passed${NC} "${BLUE}The Installation has been successfully completed...${NC}"
else
    print_result ${RED}Failed${NC} "${RED}The installation has been finished with errors...${NC}"
fi
