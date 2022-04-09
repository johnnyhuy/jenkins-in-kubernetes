ENV ?= local

local-cluster:
	minikube start --memory 7936m --cpus 3 --apiserver-names=host.docker.internal

helm-repo-add:
	./bin/helm-repo-add.sh

dev:
	skaffold dev -p $(ENV)

dev-jenkins:
	skaffold dev -p $(ENV) -m jenkins

dev-monitoring:
	skaffold dev -p $(ENV) -m kube-system

dev-chaos:
	skaffold dev -p $(ENV) -m chaos-testing

deploy:
	skaffold build -q | skaffold deploy -p $(ENV) --build-artifacts -

deploy-jenkins:
	skaffold deploy -p $(ENV) -m jenkins

deploy-monitoring:
	skaffold deploy -p $(ENV) -m kube-system

deploy-chaos:
	skaffold deploy -p $(ENV) -m chaos-testing

render-jenkins:
	skaffold build -p $(ENV) --dry-run -q | skaffold render -p $(ENV) -m jenkins --digest-source=local -a -

tunnel:
	minikube tunnel -c
