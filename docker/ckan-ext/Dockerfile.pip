FROM ckan:ckan-2.8.2

LABEL io.k8s.display-name="Add CKAN extension via pip install" \
	io.k8s.description="Docker build that installs ckan extensions on already configured CKAN image" \
  io.openshift.expose-services="5000/http:ckan" \
  io.openshift.tags="ckan,python-2.7,ckan-ext,git" \
  maintainer="dan.punga@gmail.com" \
  description="Docker build that installs ckan extensions on already configured CKAN image" \
  ckan-extensions="${CKAN_EXT_LIST}"

# this is run under user 1001
RUN source $APP_ROOT/etc/generate_container_user && \
# need to enable alternate packages
	source $APP_ROOT/etc/scl_enable && \
	pip install ${CKAN_EXT_LIST} && \
	fix-permissions ${APP_ROOT}
