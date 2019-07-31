#!/bin/bash

############################# Extended version from the original ckan_entrypoint.sh ############################
#
# original: https://github.com/ckan/ckan/blob/master/contrib/docker/ckan-entrypoint.sh
#
# Initializes the CKAN container via a Kubernetes/Openshift  init container
# by setting up the configuration .ini files for CKAN
#
# If a "who.ini" file is supplied in the $CKAN_CONF_TEMPLATES location, via a ConfigMap,
# it will be copied to the $CKAN_CONFIG location and used. Otherwise the default file
# under $APP_ROOT/src/ckan/ckan/config/who.ini will be used
#
# If the deployment uses a "ckan.ini" template file which contains configuration with bash-like variables,
# the script processes the template found at $CKAN_CONF_TEMPLATES/ckan.ini
# based on environment variables.
# If the deployment uses an already configured ckan.ini file, it will be copied and used as is.
#
# The means of choosing between the 2 deployment version is by supplying the environment variable
# CKAN_USE_CONF_TEMPLATE. If set to "true" it will search for a template named ckan.ini
# in the $CKAN_CONF_TEMPLATES location(the mount point of the ConfigMap), process it and copy
# the useable file in the $CKAN_CONFIG location. IF set to another value("false"), it will
# copy the unprocessed .ini file in the $CKAN_CONFIG location to be used by the ckan process as is.
################################################################################################################


set -e

CKAN_CONF_TEMPLATES=${CKAN_CONF_TEMPLATES:-/ckan-conf-templates}

# need to have a file supplied; either template or raw
if [ ! -s "$CKAN_CONF_TEMPLATES/ckan.ini" ]; then
	echo "$CKAN_CONF_TEMPLATES/ckan.ini not found; Exiting" >&2
	exit 1
fi

who_file="$APP_ROOT/src/ckan/ckan/config/who.ini"
if [ -s "$CKAN_CONF_TEMPLATES/who.ini" ]; then
	who_file="$CKAN_CONF_TEMPLATES/who.ini"
	echo "---> Using the supplied $who_file"
else
	echo "---> Using the default $who_file"
fi
cp -f "$who_file" "$CKAN_CONFIG/who.ini"

# copy ConfigMap file to the CKAN_CONFIG editable location
cp -f "$CKAN_CONF_TEMPLATES/ckan.ini" "$CKAN_CONFIG/ckan.ini"
CONFIG="$CKAN_CONFIG/ckan.ini"

if [ -z "$CKAN_USE_CONF_TEMPLATE" ] || [ "$CKAN_USE_CONF_TEMPLATE" != "true" ]; then
	echo "---> Use raw configuration file from $CKAN_CONF_TEMPLATES/ckan.ini"
	echo "---> CKAN will be started with the configuration below:"
	cat "$CONFIG"
	echo "---> END $CONFIG"
	exit 0
fi

# remaining of the procedure is in the case the ckan.ini file is a template

# values in req_env_vars will be checked for existence; if check fails, deployment is aborted
req_env_vars=(PG_USER PG_PASSWORD POSTGRES_HOST PG_DATABASE SOLR_HOST SOLR_PORT REDIS_HOST REDIS_PORT REDIS_DB DATAPUSHER_HOST \
		DATAPUSHER_PORT PG_DATASTORE_DB PG_DATASTORE_RO_USER PG_DATASTORE_RO_PASS)

#check needed env before doing anything
missing_req=0
for var in ${req_env_vars[@]}
do
	if [ "x"$(eval echo "\$$var") = "x" ]; then
		if [ $missing_req -eq 0 ]; then
			missing_req=1
			echo "ERROR: One or more needed environment variables not set" >&2
		fi
		echo "\$$var is empty"
#	else
#		echo "\$$var="$(eval echo "\$$var")
	fi
done
if [ $missing_req -eq 1 ]; then
	echo "ABORTING" >&2
  exit 1
fi

# Wait 10 min for PostgreSQL DB to become ready
count=1
while [[ ! $(pg_isready -h $POSTGRES_HOST -U $PG_USER) ]] && [[ $count -le 60 ]]
do
	echo "---> Waiting for postgresql DB at $POSTGRES_HOST to become ready for user $PG_USER"
	let count=$count+1
  sleep 10;
done

# since all ckan vars are present on env, get entire env and try substitute everything with sed
echo "---> Update $CONFIG based on env vars"
all_env=($(env | cut -d '=' -f 1))
for var in ${all_env[@]}
do
	# will just use the env vars that contain upper-case letters, numbers and _
	var=$(echo $var | sed -n "s|[A-Z][[A-Z0-9]_]*|&|p")
	if [ ${#var} -eq 0 ]; then
		continue
	fi
	val=$(eval echo "\$$var")
	# if $var is not present in the config file, it will just be skipped/not replaced
	# problem with confounding variables(from upstream docker layers)....CKAN env vars need to have unique name/naming convention
	# use sed separator as | because values can be URLs which contain /
	sed -i "s|\$$var|$val|g" "$CONFIG"
done

# !!! need to check if DB is already initialized/setup
if [ -n "$CKAN_DO_DB_INIT" ] && [ "$CKAN_DO_DB_INIT" = "true" ]; then
	echo "---> Initialize database using $CKAN_CONFIG/ckan.ini configuration"
	paster --plugin=ckan db init -c "$CKAN_CONFIG/ckan.ini"
	paster --plugin=ckan datastore set-permissions -c "$CKAN_CONFIG/ckan.ini" > "$CKAN_CONFIG/datapusher_setup.sql"


	echo "---> For Datapusher creation/initialization, need to run the following sql snippet on the postgres DB:"
	echo "---> Script saved as $CKAN_CONFIG/datapusher_setup.sql"
	echo "=======================BEGIN sql============================"
	cat "$CKAN_CONFIG/datapusher_setup.sql"
	echo "=======================END sql=============================="
fi

echo "---> CKAN will be started with the configuration below:"
cat "$CONFIG"
echo "---> END $CONFIG"

exec "$@"