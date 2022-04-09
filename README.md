# Jenkins

🤵🏼‍♂️ Jenkins on Kubernetes powered by Minikube. But examples here can apply beyond local cluster tools.

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

### How

Edit `jenkins.config` in Helm chart `values.yaml` files.

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
        url: http://${JENKINS_URL}:8080
```

To view **existing** Jenkins configuration, from Jenkins home, go to `Configuration as Code -> Documentation`

We can also copy [examples](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos).

#### Environment variables

We can plug in environment variables into CaC config. This is done with the `jenkins.env` Helm chart values.

`values.yaml`

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

#### Secrets

Secrets can be loaded through Kubernetes secrets, by persisting CaC YAML configuration in secret. This file needs to be in the [`charts/jenkins/templates`](./charts/jenkins/templates) folder of the Jenkins helm chart. 

We'll need to add the `jenkins-jenkins-config: "true"` label on the Kubernetes secret to allow Jenkins to auto reload.

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
