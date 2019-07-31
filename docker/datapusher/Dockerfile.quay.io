#!!! this Dockerfile is only used for quay.io builds mimicking S2I
FROM docker.io/centos/python-27-centos7

ENV DISABLE_SETUP_PY_PROCESSING "true"
ENV UPGRADE_PIP_TO_LATEST "true"

ARG git_branch="0.0.15"

RUN git clone https://github.com/ckan/datapusher.git /tmp/appsrc/ && \
	cd /tmp/appsrc && \
	git checkout ${git_branch} && \
	cp -rf /tmp/appsrc/* $APP_ROOT/src/ && \
	rm -rf /tmp/appsrc && \
	cd && \
	$STI_SCRIPTS_PATH/assemble
