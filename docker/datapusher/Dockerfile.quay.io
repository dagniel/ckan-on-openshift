#!!! this Dockerfile is only used for quay.io builds mimicking S2I
FROM docker.io/centos/python-27-centos7

ENV DISABLE_SETUP_PY_PROCESSING "true"
ENV UPGRADE_PIP_TO_LATEST "true"

ARG git_branch="0.0.15"

RUN git clone https://github.com/ckan/datapusher.git $APP_ROOT/src/ && \
	cd $APP_ROOT/src && \
	git checkout ${git_branch} && \
	cd

CMD $STI_SCRIPTS_PATH/assemble