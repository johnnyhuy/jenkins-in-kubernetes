#!/bin/bash

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kubeinvaders https://lucky-sideburn.github.io/helm-charts
helm repo add jenkins https://charts.jenkins.io