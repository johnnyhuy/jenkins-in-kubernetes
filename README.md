[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<br />
<div align="center">
    <a href="https://github.com/johnnyhuy/jenkins">
    <img src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.svg" alt="Logo" width="80" height="80">
    <img src="https://upload.wikimedia.org/wikipedia/commons/e/e9/Jenkins_logo.svg" alt="Logo" width="80" height="80">
    </a>
    <h3 align="center">Jenkins</h3>
    <p align="center">
    🤵🏼‍♂️ Jenkins on Kubernetes powered by Minikube. But examples here can apply beyond local cluster tools.
    <br />
    <br />
    <a href="#getting-started">Getting Started</a>
    <br />
    <a href="#access">Access</a>
    ·
    <a href="#configuration-as-code">Configuration as Code</a>
    <br />
    <a href="#findings">Findings</a>
</div>

## Background


### Built With

Notable resources including, but not limited to:

* [Jenkins Helm chart](https://github.com/jenkinsci/helm-charts)
* [Jenkins Docker image](https://hub.docker.com/r/jenkins/jenkins)
* [Jenkins inbound agents](https://github.com/jenkins-infra/docker-inbound-agents)
* [Helm](https://helm.sh/)
* [Skaffold](https://skaffold.dev/)


## Getting started

```bash
# Install a required tooling
brew bundle

# Startup Kubernetes cluster
make local-cluster

# Deploy everything and watch for changes
make dev

# Fire and forget deployment
make deploy
```

### Access

```bash
# Create a Minikube tunnel since we've exposed ports to certain services
make tunnel
```

Jenkins - [`localhost:8080`](http://localhost:8080)

Grafana - [`localhost:3000`](http://localhost:3000)

Prometheus - [`localhost:9090`](http://localhost:9090)

## Configuration as Code

> Experienced Jenkins users rely on groovy init scripts to customize Jenkins and enforce the desired state. Those scripts directly invoke Jenkins API and, as such, can do everything (at your own risk). But they also require you to know Jenkins internals and are confident in writing groovy scripts on top of Jenkins API.

An alternative to using imperative Groovy scripts to setup Jenkins. We can use declarative configuration through the the [configuration as code](https://github.com/jenkinsci/configuration-as-code-plugin) (CaC) Jenkins plugin.

Configuration is controlled at the [Helm chart values](./charts/jenkins/values.yaml) where they get templated into [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/). Jenkins has a sidecar that [auto-reloads](https://github.com/jenkinsci/helm-charts/tree/main/charts/jenkins#config-as-code-with-or-without-auto-reload) configuration upon each update (Helm chart release).

### Jenkins configuration

Edit `jenkins.config` in Helm chart [`values.yaml`](./charts/jenkins/values.yaml) files.

```yaml
jenkins:
  config:
    # Configuration as code config example
    security:
      apiToken:
        creationOfLegacyTokenEnabled: false
        tokenGenerationOnCreationEnabled: false
        usageStatisticsEnabled: false
    unclassified:
      location:
        adminAddress: 
```

To view **existing** Jenkins configuration, from Jenkins home, go to `Configuration as Code -> Documentation`

We can also copy [examples](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos).

### Agents

Jenkins agents can be added through CasC through Helm chart values files. Helm templates configuration 

- [Agent plugin reference](https://plugins.jenkins.io/kubernetes/#plugin-content-pod-template)
- [Example agent Docker images](https://github.com/jenkins-infra/docker-inbound-agents)

[`values.yaml`](./charts/jenkins/values.yaml)

```yaml
jenkins:
  agents:
    default:
      label: "default"
      containers:
      - name: "jnlp"
        image: "jenkins/inbound-agent:4.11.2-4"
    example-gradle-monogo:
      label: "gradle"
      containers:
      - name: "jnlp"
        image: "johnnyhuy/jenkins-gradle:latest"
        privileged: true
        envVars:
          - envVar:
              key: "EXAMPLE"
              value: "foobar"
      - name: "mongo"
        image: "mongo:latest"
        args: "^${computer.jnlpmac} ^${computer.name}"
      idleMinutes: 0
      instanceCap: 2147483647
      label: default
      nodeUsageMode: EXCLUSIVE
      podRetention: Never
      showRawYaml: true
      serviceAccount: default
      slaveConnectTimeoutStr: 100
      yamlMergeStrategy: override
    example-node-mysql:
      label: "node"
      containers:
      - name: "jnlp"
        image: "johnnyhuy/jenkins-node:latest"
      - name: "mysql"
        image: "mysql:latest"
```

### Environment variables

We can plug in environment variables into CaC config. This is done with the `jenkins.env` Helm chart values.

[`values.yaml`](./charts/jenkins/values.yaml)

```yaml
jenkins:
  # Jenkins master environment variables
  controller:
    containerEnv:
      - name: SPICY_SECRET
        value: spice123
  
  # Configuration as code config
  config:
    credentials:
      system:
        domainCredentials:
          - credentials:
            - string:
              id: "spicy-secret"
              secret: ${SPICY_SECRET}
```

### Secrets

Secrets can be loaded through Kubernetes secrets, by persisting CaC YAML configuration in secret. This file needs to be in the [`charts/jenkins/templates`](./charts/jenkins/templates) folder of the Jenkins helm chart. 

We'll need to add the `jenkins-jenkins-config: "true"` label on the Kubernetes secret to allow Jenkins to [auto-reload](https://github.com/jenkinsci/helm-charts/tree/main/charts/jenkins#config-as-code-with-or-without-auto-reload).

`charts/jenkins/template/spicy-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: spicy-secret
  labels:
    # Jenkins detects and auto-reloads
    jenkins-jenkins-config: "true"
stringData:
  # Filename to be loaded into Jenkins
  spicy-casc-config.yaml:
    # Follows the same CasC format
    config:
      credentials:
        system:
          domainCredentials:
            - credentials:
              - string:
                id: "spicy-secret"
                secret: spicy123
```

[Source](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#kubernetes-secrets)

## Findings

### Jenkins unstable on ARM

If we're using Jenkins on ARM systems like M1 Macs, it's recommended to use ARM64 Docker images to avoid JVM crashes. Thankfully Jenkins have provided newer images with ARM support. However, older images like `jenkins/jenkins:2.263.4-lts` remain on AMD64.

[GitHub issue](https://github.com/jenkinsci/docker/issues/941)

## Where and what is JNLP?

Java Network Launch Protocol aka JNLP is the protocol Jenkins agents historically use communicate between master and agent instances. JNLP has been deprecated in version 9+ of Java. Nowadays it's recommended to use either TCP or WebSockets as a replacement.

[contributors-shield]: https://img.shields.io/github/contributors/johnnyhuy/jenkins.svg?style=for-the-badge
[contributors-url]: https://github.com/johnnyhuy/jenkins/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/johnnyhuy/jenkins.svg?style=for-the-badge
[forks-url]: https://github.com/johnnyhuy/jenkins/network/members
[stars-shield]: https://img.shields.io/github/stars/johnnyhuy/jenkins.svg?style=for-the-badge
[stars-url]: https://github.com/johnnyhuy/jenkins/stargazers
[issues-shield]: https://img.shields.io/github/issues/johnnyhuy/jenkins.svg?style=for-the-badge
[issues-url]: https://github.com/johnnyhuy/jenkins/issues
[license-shield]: https://img.shields.io/github/license/johnnyhuy/jenkins.svg?style=for-the-badge
[license-url]: https://github.com/johnnyhuy/jenkins/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/johnnyhuy/
[product-screenshot]: ./images/project-image.png
