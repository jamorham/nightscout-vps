#!/bin/bash

echo
echo "This program will copy all your heroku vars into a file and allow you to use them in your new site"
echo

#install the heroku cli
curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

echo please enter your heroku details.
heroku login -i

APP_NAME=$(heroku apps -A --json | jq '.[] | .["name"]' | sed -e 's/\"//g')
echo $APP_NAME
heroku config -a $APP_NAME -s| grep -v  "STORAGE_URI\|MONGO_CONNECTION\|MONGO$\|MONGOLAB_URI\|MONGODB_URI" |  sed -e 's/^/export /' > heroku_vars.txt

echo "new vars are in the file heroku_vars.txt."
echo "Please look at it, and if all is ok, try copying it to /etc/nsconfig"
