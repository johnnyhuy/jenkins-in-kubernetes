# Jenkins

🤵🏼‍♂️ Jenkins on Kubernetes

## Getting started


```bash
# Install a required tooling
brew bundle

# Startup Kubernetes cluster
minikube start

# (optional) Deploy Kubernetes specific apps
kubectl apply -k kube-apps

# Deploy Jenkins and watch for changes
skaffold dev
```

Access Jenkins through [`localhost:8080`](http://localhost:8080)

## Findings

### Configuration as Code

> Experienced Jenkins users rely on groovy init scripts to customize Jenkins and enforce the desired state. Those scripts directly invoke Jenkins API and, as such, can do everything (at your own risk). But they also require you to know Jenkins internals and are confident in writing groovy scripts on top of Jenkins API.

An alternative to using imperative Groovy scripts to setup Jenkins. We can use declarative configuration through the the [configuration as code](https://github.com/jenkinsci/configuration-as-code-plugin) (CaC) Jenkins plugin.

Find out how to configure plugins with [examples](https://github.com/jenkinsci/configuration-as-code-plugin#initial-configuration). The CaC plugin has functionalitiy 

### Handling secrets

We can use the CaC plugin's functionality to fetch secrets through Kubernetes secrets as variables. It reads each file in `/run/secrets/` and uses the filename as the variable name.


`secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: spicy-secret
stringData:
  spicysecret: 'my spicy secret
```

`jenkins-config.yaml`

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
        - string:
          id: "spicy-secret"
          secret: ${spicysecret}
```

[Source](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#kubernetes-secrets)

## Where and what is JNLP?

Java Network Launch Protocol aka JNLP is the protocol Jenkins agents historically use communicate between master and agent instances. JNLP has been deprecated in version 9+ of Java. Nowadays it's recommended to use either TCP or WebSockets as a replacement.
