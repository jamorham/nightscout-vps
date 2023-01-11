import os
import sys
import re
from json import loads

class Object(object):
    def __init__(self, key="", value="", description="", default=""):
        self.key = key
        self.value = value
        self.description = description
        self.default = default

    def __str__(self):
        return "Key " + self.key + " value " + self.value + "desc " + self.description + "default " + self.default


class DB:
    def __init__(self, path):
        self.path = path
        self.possible_items = []

    def parse_line(line):
        #print("in parse line", line,  ":".join("{:02x}".format(ord(c)) for c in line))
        line = line.replace("'", "")
        match = re.match("export *(.*)=[\"'](.*)[\"']", line, re.MULTILINE|re.DOTALL)
        if match:
            return Object(match.group(1), match.group(2))
        else:
            match = re.match("export *(.*)=(.*)", line, re.MULTILINE|re.DOTALL)
            if match:
                return Object(match.group(1), match.group(2))
        return None

    def get_possible_items(self):
        return self.possible_items


    def get_items(self):
        APP_JSON_FILE = os.environ.get('APP_JSON_FILE')
        if not APP_JSON_FILE:
            print("system must load with APP_JSON_FILE. use \"export APP_JSON_FILE=/path/to/file\" before starting")
            os._exit(1)

        items = []
        new_items = []
        requireds = []
        self.possible_items = []
        if not os.path.exists(self.path):
            return items
        file = open(self.path, "r+")
        lines = file.read().split("export")  # can not read two-line value correctly.
        del lines[0]
        file.close()
        js = read_app_json(APP_JSON_FILE)
        for line in lines:
            line = line.strip()
            item = DB.parse_line("export " + line)
            if line == "":
                continue;
            if not item:
                print("Something went wrong. couldn't parse", line)
                continue;
            if item.key in js:
                item.description = js[item.key]["description"]
                item.default = js[item.key]["value"]
                item.required = js[item.key]["required"]
                del js[item.key]
                if item.required == "true":
                    requireds.append(item)
                else:
                    items.append(item)
            else:
                item.description = "--no descrition--"
                new_items.append(item)

        items = requireds + items + new_items  # so new keys would appear in the end of the table
        for key in js:
            item = Object(key, "", js[key]["description"], js[key]["value"])
            self.possible_items.append(item)
        return items;

    def convert_item(self, item):
        #val = item.value.replace("\r", "")
        #val = val.replace("'", "'\''") # make sure that we escape ' signs. See https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings
        val = item.value.replace("'","")
        val = val.replace("\r", "")
        return str('export ' + item.key + "='" +val + "'")

    def append_item(self, item):
        file = open(self.path, "a")
        newline = "\n" + self.convert_item(item)
        file.write(newline)
        file.close()

    def change_item(self, item):
        items = self.get_items()
        open(self.path, "w").close()  # delete all file content.
        file_lines = []
        for it in items:
            if it.key == item.key:
                it.value = item.value
            file_lines.append(self.convert_item(it) + "\n")
        file = open(self.path, "w")
        file.writelines(file_lines)
        file.close()

    def remove_item(self, key):
        items = self.get_items()
        file_lines = []
        open(self.path, "w").close()  # delete all file content.
        for it in items:
            if it.key == key:
                continue;
            file_lines.append(self.convert_item(it) + "\n")
        file = open(self.path, "w")
        file.writelines(file_lines)
        file.close()

def read_app_json(app_json_file):

    if not os.path.exists(app_json_file):
        print("app.json File not found ", app_json_file)
        return []
    with open(app_json_file, "r") as file:
        js = file.read()
    print(js)
    return loads(js)["env"]


def test_line(line, expected_key, expected_val):
    out = DB.parse_line(line)
    if out.key != expected_key or out.value != expected_val:
        print("test failed for line", line, "out.key=", out.key, "out.value=", out.value)
        print("expected value", expected_val,  ":".join("{:02x}".format(ord(c)) for c in expected_val))
        print("actual value  ",   out.value,  ":".join("{:02x}".format(ord(c)) for c in out.value))


def test_re():
    print("testint")
    test_line('export xxx="1"', "xxx", "1")
    test_line('export xxx=1', "xxx", "1")
    test_line('export xxx="1 2"', "xxx", "1 2")
    test_line('export xxx=1 2', "xxx", "1 2")
    test_line('export xxx="1 \"2"', "xxx", "1 \"2")
    test_line('export xxxb="1 \'*\'2"', "xxxb", "1 *2")
    # does not work test_line('export xxx="1 "*"2"', "xxx", "1")
    test_line("export xxx='1'", "xxx", "1")
    test_line("export xxx='1 \"2'", "xxx", "1 \"2")
    test_line("export xxx=1abc\ndef", "xxx", "1abc\ndef")
    test_line("export xxx='2abc\ndef'", "xxx", "2abc\ndef")
    test_line("export xxx='3abc\ndef\n'", "xxx", "3abc\ndef\n")
    test_line("export xxx='4abc \ndef\n '", "xxx", "4abc \ndef\n ")
    test_line("export xxx='5abc @&*$%\ndef\n '", "xxx", "5abc @&*$%\ndef\n ")
    test_line("export xxx='1\r'", "xxx", "1\r")
    test_line("export xxxa='1'\''", "xxxa", "1")



if __name__ == "__main__":
    test_re()
