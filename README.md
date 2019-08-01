# ckan-on-openshift
CKAN deployment configuration for Openshift

## CKAN 

If the entire stack of templated components, that are needed by CKAN, has been consistently deployed (using the same application NAME and Openshift NAMESPACE),
the parametrized `Secret` object that holds setup environment variables for CKAN(default is called `${NAME}-env`) should just work.

If CKAN has to connect to specific endpoints for Redis, Datapusher, SOlr and Postgres, then the `Secret` must be manually edited accordingly.

## Solr
Images are found at https://quay.io/repository/dagniel/ckan.solr-on-openshift<br>
The "base-" images are built based on the Docker configuration from ckan's repository for convenience(the images aren't built and pushed to a public image repository).<br>
The Openshift specific image relies on the base image and is tagged with just the version of the original solr("6.6.2", "6.6.5"")

## Datapusher


***Note**: The choice to create a new image for datapusher is because the default image, pointed inside the docker-compose.yml file
in the original CKAN repository, is 4 years old(at the time of this writing); see https://hub.docker.com/r/clementmouchet/datapusher/tags*

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
- mention: all current config for custom builds is done based on publicly acessibly repos; for private repos the BuildConfigs must be customized
- mention: for postgres users and passwords are generated from template's params by using expressions

