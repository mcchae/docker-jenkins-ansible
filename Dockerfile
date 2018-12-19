FROM jenkinsci/jenkins:2.154
# debian 9 base
MAINTAINER MoonChang Chae mcchae@argos-labs.com
LABEL Description="Jenkins 2.154 with python3 ansible"

ENV TZ=Asia/Seoul
ENV ANSIBLE_STDOUT_CALLBACK=debug
USER root
COPY get-pip.py /tmp

## for python 3.7
#RUN apt-get update && \
#	apt-get install -y make build-essential libssl-dev zlib1g-dev && \
#	apt-get install -y libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm && \
#	apt-get install -y libncurses5-dev libncursesw5-dev xz-utils tk-dev && \
#	apt-get install -y libsecret-1-dev && \
#	cd /usr/local && \
#	wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz && \
#	tar xzf Python-3.7.0.tgz && \
#	cd Python-3.7.0 && \
#	./configure --prefix=/usr --enable-optimizations --with-ensurepip=install && \
#	make && \
#	make install && \
#	#chmod +x python3.7 && \
#	cd .. && \
#	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
#	python3 get-pip.py && \
#	rm get-pip.py && \
#	rm -f /usr/bin/python && \
#	ln -s /usr/local/bin/Python-3.7.0/python /usr/bin/python

# for python 3.6
RUN	echo "deb http://ftp.de.debian.org/debian testing main" >> /etc/apt/sources.list && \
	echo 'APT::Default-Release "stable";' >> /etc/apt/apt.conf.d/00local && \
	apt-get update && \
	apt-get -t testing install -y python3.6
#
#	python3 -V
#
#RUN pip install -U pip && \
#	pip install ansible pywinrm PyVmomi && \
#	apt-get install -y sshpass && \
#	mkdir /var/ansible

VOLUME /var/ansible
USER jenkins
