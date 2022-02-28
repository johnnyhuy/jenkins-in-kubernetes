FROM --platform=linux/amd64 jenkins/jenkins:2.263.4-lts

USER root
RUN curl -kL https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.3/jenkins-plugin-manager-2.12.3.jar -o /opt/jenkins-plugin-manager.jar
USER jenkins

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/plugins.txt
