FROM jenkinsci/jenkins:2.154
MAINTAINER MoonChang Chae mcchae@argos-labs.com
LABEL Description="Jenkins 2.154 with python3 ansible"

ENV TZ=Asia/Seoul
ENV ANSIBLE_STDOUT_CALLBACK=debug
USER root
COPY get-pip.py /tmp
RUN apt-get update && \
	apt-get install -y python3 && \
	python3 /tmp/get-pip.py && \
	pip install -U pip && \
	pip install ansible pywinrm && \
	apt-get install -y sshpass && \
	mkdir /var/ansible
VOLUME /var/ansible
USER jenkins
