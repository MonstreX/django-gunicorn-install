# Django Gunicorn installation script
This script installs gunicorn wsgi server for your Django project.

# Pre-requirements

### Server
- Nginx web server should be installed.
- Make sure you have appropriate rights on your current user and files permissions.

### Initial project structure
Here 'main' is the main (with settings.py) folder of the Django project. The Django folde may store deeper in the folder structure, setup script will find it anyway.
```sh
/var/www/django-example.com/
  .gunicorn/
  .nginx/
  main/
  manage.py
  requirements.txt
  install.sh
  uninstall.sh
```

# Installation
Copy your Django project in the folder with the installation script. Then just run:

>./install.sh

That's it.
