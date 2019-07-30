FROM centos/python-27-centos7

LABEL io.k8s.display-name="Custom CKAN main container build for OKD" \
	io.k8s.description="Custom build for CKAN main container based on https://github.com/ckan/ckan.git based on official python-2.7 image" \
  io.openshift.expose-services="5000/http:ckan" \
  io.openshift.tags="ckan,python-2.7" \
  maintainer="dan.punga@gmail.com" \
  description="Custom build for CKAN main container based on https://github.com/ckan/ckan.git based on official python-2.7 image"

USER 0

RUN INSTALL_PKGS="libxml2-devel libxslt-devel openssl-devel libffi-devel git" && \
# need to install epel-release repo for the geos-devel package adn disable it avoid possible conflicts
	yum install -y epel-release && \
	sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo && \
	yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
	rpm -V $INSTALL_PKGS && \
	INSTALL_PKGS="${PGSQL_SCL}-postgresql-devel ${PGSQL_SCL}-postgresql" && \
	yum -y --setopt=tsflags=nodocs install --enablerepo=centos-sclo-rh $INSTALL_PKGS && \
	rpm -V $INSTALL_PKGS && \
	yum -y --setopt=tsflags=nodocs install --enablerepo=epel geos-devel && \
	rpm -V geos-devel && \
	yum -y clean all --enablerepo='*'

# using base container env vars
COPY ./root/ /
COPY ./config $APP_ROOT/config
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# move and remake permissions for the newly added files
RUN mv -f $APP_ROOT/config/app.sh $APP_ROOT/src/app.sh && \
	chmod ug+x $APP_ROOT/src/app.sh && \
  chown -R 1001:0 ${APP_ROOT} && \
  fix-permissions ${APP_ROOT} && \
  chmod -R a+x $STI_SCRIPTS_PATH/

USER 1001

EXPOSE 5000

# Set the default CMD to print the usage of the language image.
CMD $STI_SCRIPTS_PATH/usage