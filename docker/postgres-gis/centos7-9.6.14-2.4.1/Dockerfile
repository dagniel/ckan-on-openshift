FROM docker.io/crunchydata/crunchy-postgres-gis:centos7-9.6.12-2.4.1

LABEL io.k8s.display-name="Custom CKAN postgres build" \
	io.k8s.description="Custom build for CKAN postgresql container based on https://github.com/CrunchyData/crunchy-containers/tree/2.4.1" \
  io.openshift.expose-services="5000/http:ckan" \
  io.openshift.tags="postgres, postgres-9.6.14" \
  maintainer="dan.punga@gmail.com" \
  description="Custom build for CKAN postgresql container based on https://github.com/CrunchyData/crunchy-containers/tree/2.4.1"

ENV CONTAINER_USER_NAME="postgres"

COPY bin/postgres/ /opt/cpm/bin/
COPY ./root/ /

USER 0

RUN chmod -R a+x /usr/bin && \
	yum -y clean all --enablerepo='*' && \
# fix permissions for all container used directories and files; base image has perm for others; remove them
	chmod -R 700 /opt/cpm /var/lib/pgsql /pgdata /pgwal /pgconf /recover /backrestrepo && \
	chown -R ${CONTAINER_USER_NAME}:0 /opt/cpm /var/lib/pgsql /pgdata /pgwal /pgconf /recover /backrestrepo && \
	fix_permissions /opt/cpm && \
	fix_permissions /var/lib/pgsql && \
	fix_permissions /pgdata && \
	fix_permissions /pgwal && \
	fix_permissions /pgconf && \
	fix_permissions /recover && \
	fix_permissions /backrestrepo

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]