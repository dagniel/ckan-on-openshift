#!/bin/bash

# app.sh script will be checked and run by the default s2i/bin/run script

echo "---> Call the ckan entrypoint script"
source $APP_ROOT/config/ckan_entrypoint.sh

paster serve "$CKAN_CONFIG/ckan.ini"
