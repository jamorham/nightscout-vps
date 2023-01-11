import os
from django.shortcuts import render, redirect
from django.http import HttpResponse, HttpResponseRedirect
from django.template import loader
from django.urls import reverse
import json
from variables.DB_Helper import DB, Object
from  variables import apps
import qrcode
import qrcode.image.svg
from io import BytesIO
from json import dumps
# Make sure to test this var before each request !!!
ENV_TOKEN = os.environ.get('ENV_TOKEN')
ENV_HOST = os.environ.get('HOSTNAME')

if not ENV_TOKEN:
    print("system must load with ENV_TOKEN. use \"export ENV_TOKEN=security token\" before starting")
    os._exit(1)

if not ENV_HOST:
    print("system must load with ENV_HOST. use \"export HOSTNAME=web link token\" before starting")
    os._exit(1)

NS_CONFIG_FILE = os.environ.get('NS_CONFIG_FILE')
if not NS_CONFIG_FILE:
    print("system must load with NS_CONFIG_FILE. use \"export NS_CONFIG_FILE=/path/to/file\" before starting")
    os._exit(1)
db = DB(NS_CONFIG_FILE)


def index(request):
    print("In index",type(request), request, request.GET.get('token',''), "session=" + request.session.get('token', 'mini'))
    apps.kiling_timer.ServerInUse()
    token = request.GET.get('token',request.session.get('token', ''))
    template = loader.get_template('table.html')
    if token != ENV_TOKEN:
        context = {}
        template = loader.get_template('badkey.html')
        return HttpResponse(template.render(context, request))
    # Set a session value
    request.session['token'] = token
    items = db.get_items()
    possible_items = db.get_possible_items()
    try:
        api_key = list(filter(lambda x: (x.key == "API_SECRET"), items))[0].value
    except:
        print("Alert: No API_SECRET key in config file")
        api_key = "No API_SECRET in file"
    context = {
    'variables': items,
    "possible_items" : possible_items,
    'svg' : generateQR(api_key, ENV_HOST),
    }
    return HttpResponse(template.render(context, request))

def handle_requests(request):
    print("Hi! this is handle_requests!\n\n\n")
    print(request.POST)
    apps.kiling_timer.ServerInUse()
    token = request.session.get('token', '')
    if token != ENV_TOKEN:
        context = {}
        template = loader.get_template('badkey.html')
        return HttpResponse(template.render(context, request))
    if "Add" in request.POST:
        print("add function called")
        obj = Object(request.POST["key"], request.POST["value"],)
        db.append_item(obj)
    elif "remove" in request.POST:
        print("remove function called")
        key = request.POST['remove']
        db.remove_item(key)
    elif "change" in request.POST:
         item = Object(request.POST['change'], request.POST['changedValue'])
         db.change_item(item)
         print("change function called")
    elif "default" in request.POST:
        print("default function called")
    return HttpResponseRedirect(reverse('index'))


def generateQR(key, url):
    qr_data = {}
    message = ["https://" + key + "@" + url+ "/api/v1"]
    qr_data["rest"] = {"endpoint" : message}
    factory = qrcode.image.svg.SvgImage
    img = qrcode.make(dumps(qr_data), image_factory=factory, box_size=20)
    stream = BytesIO()
    img.save(stream)
    return stream.getvalue().decode()
