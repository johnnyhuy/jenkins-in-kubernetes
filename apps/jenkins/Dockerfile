FROM jenkins/jenkins:2.332.2-lts

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/plugins.txt
