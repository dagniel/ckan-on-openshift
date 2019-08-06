FROM ckan:ckan-2.8.2

LABEL io.k8s.display-name="Add CKAN extensions via custom script" \
	io.k8s.description="Install multiple CKAN extensions based on customized script that will be injected from Secret and ran at buildtime" \
  io.openshift.expose-services="5000/http:ckan" \
  io.openshift.tags="ckan,python-2.7,ckan-ext" \
  maintainer="dan.punga@gmail.com" \
  description="Install multiple CKAN extensions based on customized script that will be injected from Secret and ran at buildtime"

# Secret injected at Docker build in current dir
COPY . $APP_ROOT/config/

USER 0

RUN chown -R 1001:0 $APP_ROOT/config && \
	chmod u+x $APP_ROOT/config/install_ckan_ext.sh && \
	fix-permissions $APP_ROOT/config/install_ckan_ext.sh

USER 1001

# script can contain either pip/python install statements so need to enable alternate packages/PATH
# script can clone repositories so need to have a system user for git to work
# !!! hack-like:
#         - OKD injects "default" as a name for uid=1001 in /etc/passwd;
#         - it will then be changed at runtime by the nss_wrapper procedure from generate_container_user
#         - prepare for this behaviour by running the below build steps with temporary user default for uid 1001
RUN CONTAINER_USER_NAME="default" && \
	source $APP_ROOT/etc/generate_container_user && \
	source $APP_ROOT/etc/scl_enable && \
	cd $APP_ROOT/src && \
	$APP_ROOT/config/install_ckan_ext.sh && \
	fix-permissions ${APP_ROOT}