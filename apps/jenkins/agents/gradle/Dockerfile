FROM jenkins/inbound-agent:jdk17-preview as jnlp

FROM --platform=linux/amd64 gradle:jdk17-alpine

COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]

ARG USER=jenkins
RUN addgroup -S $USER && adduser -S $USER -G $USER
USER $USER