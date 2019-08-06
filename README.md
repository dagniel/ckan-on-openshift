# ckan-on-openshift
CKAN deployment configuration for Openshift

## CKAN 

Only two template configuration versions are provided: 
- deployment with ephemeral persistence(emptyDir)
- local build with deployment and PersistenceVolumeClaim for data storage
Other variants can be adapted starting from these versions.

### Configuration

If the entire stack of templated components, that are needed by CKAN, has been consistently deployed (using 
the same application NAME and Openshift NAMESPACE),the parametrized `Secret` and `ConfigMap` objects that hold 
setup environment variables for CKAN should just work.

If CKAN is built with different configurations or has to connect to specific endpoints for Redis, Datapusher, SOlr and Postgres, then 
the appropriate configuration must be manually edited inside the `Secret` and/or `ConfigMap`.

#### `ckan` ConfigMap
Holds environment variables and configuration files that are CKAN(app)-specific
Components:
- `ckan.ini` main configuration file for CKAN
	- **required**
	- can be in raw/complete form so it may be used "as-is"
	- can be in templated form, which means, using environment variables; the initialization procedure(`ckan_entrypoint.sh` script) 
	will try to substitute them
- `who.ini` file 
	- optional
- `CKAN_` environment variables 
	- used at container initialization
	- there are 2 markers/flags used by the init script
		- `CKAN_USE_CONF_TEMPLATE` if set to `true`, the init script treats the supplied `ckan.ini` file as template and will try to
		substitute the variables found in it with the values of the equivalent environment variables  
    - `CKAN_DO_DB_INIT` if set to `true`, the init script will initialize the database and create and save the initialization
    script for the `datapusher` database
	- the rest of the env vars will be substituted inside the `ckan.ini` file if it is marked as being template

#### `ckan` Secret
Mainly holds environment variables that are container-specific.

## CKAN extensions

Extensions can be used by creating a new image based on CKAN.

The procedure is incremental(can add extension/layers on top of existing ones or a base CKAN) and, currently, uses 
three different approaches based on the standard generic options of adding CKAN extensions as specified in the 
official documentation: https://docs.ckan.org/en/2.8/maintaining/installing/install-from-docker-compose.html#add-extensions

### CKAN extension(s) via `pip`

#### Example (usage)
In order to add the `ckanext-geoview` and `ckanext-deadoralive` extensions:
- *(optional)* create a local ImageStream to hold your new image
- edit the `ckan-ext-pip` `BuildConfig` and modify `CKAN_EXT_LIST="ckanext-geoview ckanext-deadoralive"`
- build the new image
	- (optional) when using a local image as base for the build you should also modify the strategy as noted
	inside the `templates/ckan-extensions/ckan-ext-pip.yaml` file
- edit the ConfigMap holding the `ckan.ini` configuration file and append the plugin line 
`ckan.plugins = ... resource_proxy geo_view deadoralive`
- *(optional)* edit other configuration such as flags for template processing and/or Datastore initialization and 
other custom configuration
- edit/create the DeploymentConfig for ckan and point to the newly created ImageStream tag
- the new deployment should now be using the new image with CKAN + extensions and start based on the new `ckan.ini` file 
from the ConfigMap

#### Description
In order to add one or more CKAN extensions that are available on python's package repository, a new image must be build.
- starting from the base image of CKAN or from an image that has CKAN installed on it(and possibly other extensions)
- either using the Dockerfile from this repository(under `docker/ckan-ext/pip`) or a similar one
- the resulting image is a custom/local one, so the cluster must have the Openshift Container Repository installed in order to 
be able to store/use it

The configuration of the CKAN-extension via pip involves:
- specifying an existing image which has base CKAN(or CKAN + a set of extensions) as source image
- editing the `CKAN_EXT_LIST` environment variable with the needed list of extensions separated with a space
- building a new image and using it in a DeploymentConfiguration for CKAN
Once the configuration is loaded in Openshift/OKD, the operations above can be done from the WebConsole as well as 
by using the `oc` client (`oc edit bc/ckan-ext-pip`)

### CKAN extension via `git`

#### Example (usage)
In order to add the `ckanext-mapviews` extension:
- *(optional)* create a local ImageStream to hold your new image
- edit/create the `ckan-ext-git` `Secret` and add/modify 
	```
	CKAN_EXT_DIR: "ckanext-mapviews"
	install_ckan_ext.sh: |-
    python setup.py install
	```
- build the new image
	- (optional) when using a local image as base for the build you should also modify the strategy as noted
	inside the `templates/ckan-extensions/ckan-ext-git.yaml` file
- edit the ConfigMap holding the `ckan.ini` configuration file and append the plugin line 
`ckan.plugins = ... navigablemap` and/or `choroplethmap`
- *(optional)* edit other configuration such as flags for template processing and/or Datastore initialization and 
other custom configuration
- edit/create the DeploymentConfig for ckan and point to the newly created ImageStream tag
- the new deployment should now be using the new image with CKAN + extensions and start based on the new `ckan.ini` file 
from the ConfigMap

#### Description
Adding a single extension via `git` is similar to the actual build process of CKAN itself and it uses the `s2i` 
functionality of Openshift.
As a result only single extensions can be added at a time.

The process of adding an extension from source/ via `git` is baked in the base CKAN image. The extension is installed 
in the same directory structure along side CKAN. The resulting directory structure:<br>
$APP_ROOT(virtual environment)<br>
 |<br>
 |--ckan<br>
 |--ckan-extension-1<br>
 |--ckan-extension-2<br>
 |.... <br>

The custom BuildConfiguration uses a `Secret` object in order to configure the build process. 
The contents of the `Secret` are:
- `CKAN_EXT_DIR` holding the directory where the extension will be installed
- `install_ckan_ext.sh` script that should contain the install operations on the extension's source code 

### CKAN multiple extensions

#### Example (usage)
In order to add the `ckanext-geoview`, `ckanext-showcase`, `ckanext-mapviews` and a `custom_ckan_ext` extension from
a private repository accessible via key-pair:
- *(optional)* create a local ImageStream to hold your new image
- edit/create the `ckan-ext-multiple` `Secret` and add/modify 
	```
	install_ckan_ext.sh: |-
    #!/bin/bash

    CKAN_EXT_LIST="ckanext-geoview"
    pip install ${CKAN_EXT_LIST}

    pip install -e "git+https://github.com/ckan/ckanext-showcase.git#egg=ckanext-showcase"

    git clone https://github.com/ckan/ckanext-mapviews.git
    cd ckanext-mapviews
    python setup.py install
    cd ..

    repo_host="gitlab.myentity.net"
    repo="Project/custom_ckan_ext.git"

    setup_private_key "$APP_ROOT/config/git_priv_key1"
    ssh-agent bash -c "ssh-add $APP_ROOT/config/git_priv_key1; \
      ssh -o StrictHostKeyChecking=no -T git@$repo_host; \
      git clone git@$repo_host$repo custom_ckan_ext"
    cd custom_ckan_ext
    git checkout branch_name
    ssh-agent bash -c "ssh-add $APP_ROOT/config/git_priv_key1; \
      ssh -o StrictHostKeyChecking=no -T git@$repo_host; \
      git pull"
    
    #pip install . or other means to install the custom extension
    
    remove_private_key "$APP_ROOT/config/git_priv_key1"
    cd ..
  git_priv_key1: |-
    -----BEGIN RSA PRIVATE KEY-----
    MII.........
    ..........
    -----END RSA PRIVATE KEY-----
	```
	- *Note*: more info about the file can be found in the `templates/ckan-extensions/ckan-ext-multiple-Secret.yaml` file 
	inside this repo
- build the new image
	- (optional) when using a local image as base for the build you should also modify the strategy as noted
	inside the `templates/ckan-extensions/ckan-ext-multiple.yaml` file
- edit the ConfigMap holding the `ckan.ini` configuration file and append the plugin line 
`ckan.plugins = ... resource_proxy geo_view showcase navigablemap` and the suitable configuration for 
the`custom_ckan_ext` extension
- *(optional)* edit other configuration such as flags for template processing and/or Datastore initialization and 
other custom configuration
- edit/create the DeploymentConfig for ckan and point to the newly created ImageStream tag
- the new deployment should now be using the new image with CKAN + extensions and start based on the new `ckan.ini` file 
from the ConfigMap

## Solr
Images are found at https://quay.io/repository/dagniel/ckan.solr-on-openshift<br>
The "base-" images are built based on the Docker configuration from ckan's repository for convenience(the images aren't built 
and pushed to a public image repository).<br>
The Openshift specific image relies on the base image and is tagged with just the version of the original solr("6.6.2", "6.6.5"")

## Datapusher


***Note**: The choice to create a new image for datapusher is because the default image, pointed inside the docker-compose.yml file
in the original CKAN repository, is 4 years old(at the time of this writing); 
see https://hub.docker.com/r/clementmouchet/datapusher/tags*

## Redis

The image used for redis is switched from the default/provided in docker-compose.yml on CKAN repo.<br><br>
The default uses https://hub.docker.com/r/centos/redis.<br>
The image used in the current configuration is the redis-3.2 version from https://hub.docker.com/r/centos/redis-32-centos7

## Postgres-GIS
Only two template configuration versions are provided: 
- deployment with ephemeral persistence(emptyDir)
- local build with deployment and PersistenceVolumeClaim for data storage
Other variants can be adapted starting from these versions.

The configuration uses 2 `Secrets` and one `ConfigMap` object to allow decoupling/injection
of app specific configuration depending on environment.

The `Secret` objects define environment variables split between env-specific and authorization/identity.

The `ConfigMap`, containing the `setup.sql` script ran at initialization, is customized for CKAN.<br>
It both initializes the needed extensions and creates the Datastore structure (DB,user, pass) needed by CKAN. 

=======

# TODOs
- refine documentation
<br><br>
- decouple postgres-gis deployment from CKAN-specific datastore initialization
- extra env vars: (custom)container ports
- refactor builder dir structure for postgres-gis
- mention: all current config for custom builds is done based on publicly acessibly repos; for private repos the BuildConfigs 
must be customized
- mention: for postgres users and passwords are generated from template's params by using expressions
- patch images to solve security issues found by quay.io 

