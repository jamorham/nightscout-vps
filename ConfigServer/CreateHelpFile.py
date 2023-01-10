import urllib.request
import re
from json import loads, dumps
from variables.DB_Helper import Object, read_app_json
import os

def write_json(all_items, app_json_file):
    with open(app_json_file, "r+") as file:
        js = file.read()
        js = loads(js)
        file.seek(0)
        js["env"] = all_items
        js = dumps(js, indent=4)
        file.write(js)
        file.truncate()
        file.close()

def get_lines_url(url):
    data = urllib.request.urlopen(url).read().decode("utf8")
    data = data.replace("#### Example Queries","")
    lines = [line.rstrip() for line in data.split("\n")]
    return lines

def find_file_items(lines):
    items = []
    required = False
    for line in lines:
        if "### Required" in line:
            required = True
        elif "####" in line:
            break
        elif "###" in line:
            required = False

        match = re.match(".*\* `(.*)` ?- ?(.*)", line)
        if match:  # gets key and description, no default value.
            obj = Object(match.group(1))
            obj.description  = match.group(2)
            obj.required = required
            items.append(obj)
            print("object ", obj)
        else:
            match = re.match(".*\* `(.*)` ?\(`(.*)`\) ?- ?(.*)", line)  # gets key, default value, and description.
            if match:
                obj = Object(match.group(1))
                obj.default = match.group(2)
                obj.description = match.group(3)
                obj.required = required
                items.append(obj)
    return items

def app_file_update():
    try:
        lines = get_lines_url("https://raw.githubusercontent.com/nightscout/cgm-remote-monitor/master/README.md")
        if not lines:
            return
    except Exception as e:
        print("Could not find the page online.", e)
        print("starting")
        return
    items = find_file_items(lines)
    print("starting")
    js = read_app_json("app.json")
    for item in items:
        if item.key in js.keys(): # update data in the json file to the current one given from the web.
            js[item.key]["description"] = item.description
            js[item.key]["value"] = item.default
            js[item.key]["required"] = item.required
        else:
            js[item.key] = {"description": item.description, "value": item.default, "required": item.required}
    write_json(js, "app.json")


app_file_update()