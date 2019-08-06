FROM quay.io/dagniel/ckan.solr-on-openshift:base-6.6.5

LABEL io.k8s.display-name="Custom Solr build for OKD" \
	io.k8s.description="Custom build for Solr based on https://github.com/ckan/ckan.git suitable for OKD container security" \
  io.openshift.expose-services="8983/http:solr" \
  io.openshift.tags="solr,java" \
  maintainer="dan.punga@gmail.com" \
  description="Custom build for Solr based on https://github.com/ckan/ckan.git suitable for OKD container security"

USER 0

RUN chown -R 1001:0 /opt/solr /opt/mysolrhome /docker-entrypoint-initdb.d /opt/docker-solr && \
  chmod -R g=u /opt/solr /opt/mysolrhome /docker-entrypoint-initdb.d /opt/docker-solr

USER 1001