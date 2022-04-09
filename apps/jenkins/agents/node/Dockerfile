FROM jenkins/inbound-agent:jdk17-preview as jnlp

# Using Alpine here is broken
# since Java is tricky to copy over from jenkins/inbound-agent
FROM node:16-bullseye

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=jnlp /opt/java/openjdk "${JAVA_HOME}"
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]

ARG USER=jenkins
RUN useradd -c "Jenkins user" -m $USER \
    && chmod 750 /home/$USER
USER $USER