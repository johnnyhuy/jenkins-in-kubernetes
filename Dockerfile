FROM --platform=linux/amd64 jenkins/jenkins:2.263.4-lts

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/plugins.txt

COPY init.groovy.d/ /var/jenkins_home/init.groovy.d/
