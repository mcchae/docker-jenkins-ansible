# Jenkins with Ansible 

젠킨스 docker는 ansible 기능을 가지고 있지 않습니다. 따라서 ansible 기능을 포함하는 젠킨스 docker를 만들어 봅니다.

## 포함 내용

### Dockerfile
``` Dockerfile
FROM jenkinsci/jenkins:2.154
# debian 9 base
MAINTAINER MoonChang Chae mcchae@argos-labs.com
LABEL Description="Jenkins 2.154 with python3 ansible"

ENV TZ=Asia/Seoul
ENV ANSIBLE_STDOUT_CALLBACK=debug
USER root

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
		build-essential libsqlite3-dev sqlite3 bzip2 libbz2-dev zlib1g-dev libssl-dev openssl liblzma-dev libreadline-dev libncursesw5-dev libffi-dev uuid-dev \
        tk-dev \
        uuid-dev \
    && rm -rf /var/lib/apt/lists/*

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.7.1

RUN set -ex \
    \
    && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
    && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
    && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
    && rm -rf "$GNUPGHOME" python.tar.xz.asc \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
    && cd /usr/src/python \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --without-ensurepip \
    && make -j "$(nproc)" \
    && make install \
    && ldconfig \
    \
    && find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' + \
    && rm -rf /usr/src/python \
    \
    && python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && ln -s idle3 idle \
    && ln -s pydoc3 pydoc \
    && ln -s python3 python \
    && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.1

RUN set -ex; \
    \
    wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
    \
    python3 get-pip.py \
        --disable-pip-version-check \
        --no-cache-dir \
        "pip==$PYTHON_PIP_VERSION" \
    ; \
    pip --version; \
    \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
    rm -f get-pip.py


RUN pip install -U pip && \
	# for ansible
	pip install ansible pywinrm PyVmomi && \
	# for AWS S3
	pip install awscli boto  && \
	apt-get update && \
	apt-get install -y sshpass && \
	mkdir /var/ansible

VOLUME /var/ansible
USER jenkins

```

* KST로 TimeZone 설정 (Asia/Seoul)
* ansible을 이용할 때 ssh 암호를 이용하려면 sshpass 패키지 필요
* ANSIBLE_STDOUT_CALLBACK=debug 환경변수를 지정하면 stdout/stderr 이 그대로의 읽기 쉬운 결과를 보여줌
* ansible에 윈도우 연결을 위해 pywinrm 패키지 필요
* ansible에 ESXi 서버 핸들링을 위해 PyVmomi 패키지 필요
* 디폴트로 설치되는 python 3.5.3 은 아래와 같은 오류를 발생하므로 파이썬 3.6으로 올림

> TypeError: 'NoneType' object is not callable
> Exception ignored in: <function WeakValueDictionary.__init__.<locals>.remove at 0x7f6254a86840>
> Traceback (most recent call last):
>   File "/usr/lib/python3.5/weakref.py", line 117, in remove


### Jenkins
* 버전 2.154

### ansible

#### Python
* 파이썬 버전 3.7.1 (기존의 3.5.3 은 ansible을 돌리면서 오류 메시지 자주 발생)
* pip 버전 18.1

##### Ansible
* 앤시블 버전 2.7.4

##### AWS & S3
* using awscli
* S3 using boto

## 사용 예

보통 젠킨스와 동일하게 사용

### docker run

```
docker run -p 8080:8080 -p 50000:50000 mcchae/jenkins-ansible
```

### docker compose

다음과 같이 docker-compose.yaml 을 이용할 수 있음

``` yaml
version: '2'
services:
  mailhog:
    image: mailhog/mailhog
    container_name: mail
    ports:
      - "1025:1025"
      - "8025:8025"
  jenkins:
    image: mcchae/jenkins-ansible
    container_name: jenkins
    user: jenkins
    volumes:
      # 다음의 host volumn의 uid:gid는 1000:1000 이어야 함
      - /root/compose/dhv/jenkins:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/naswork/crpa/ansible:/var/ansible
    environment:
      JENKINS_HOST_HOME: "/data/jenkins"
    ports:
      - "8080:8080"
      - "5000:5000"
      - "50000:50000"
```

> mailhog 이미지는 jenkins에서 메일을 보내기 위한 컨테이너인데 테스트를 해 보니 제대로 나가지 않아 제외하고 gmail을 이용하여 보내고 있음

