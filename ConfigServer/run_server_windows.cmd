
set SECRET_KEY=aaa
set ENV_DEBUG=True
set ENV_TOKEN=aaa
set NS_CONFIG_FILE=example.txt
set HOSTNAME=snirdev1.mooo.com
set APP_JSON_FILE=app.json

pip install django-extensions Werkzeug
pip install qrcode
python manage.py runserver