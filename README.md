# Jenkins with Ansible 

젠킨스 docker는 ansible 기능을 가지고 있지 않습니다. 따라서 ansible 기능을 포함하는 젠킨스 docker를 만들어 봅니다.

## 포함 내용

### Dockerfile
``` Dockerfile
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
```

* KST로 TimeZone 설정 (Asia/Seoul)
* ansible을 이용할 때 ssh 암호를 이용하려면 sshpass 패키지 필요
* ANSIBLE_STDOUT_CALLBACK=debug 환경변수를 지정하면 stdout/stderr 이 그대로의 읽기 쉬운 결과를 보여줌


### Jenkins
* 버전 2.154

### ansible

#### Python
* 파이썬 버전 3.5.3
* pip 버전 18.1

##### Ansible
* 앤시블 버전 2.7.4

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

