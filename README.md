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

## Findings

### Configuration as Code

An alternative to using imperative Groovy scripts to setup Jenkins. We can use declarative configuration through the the [configuration as code](https://github.com/jenkinsci/configuration-as-code-plugin) Jenkins plugin.
