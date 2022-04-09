{{/*
Returns the Jenkins URL
*/}}
{{- define "jenkins.url" -}}
{{- if .Values.jenkins.controller.jenkinsUrl }}
  {{- .Values.jenkins.controller.jenkinsUrl }}
{{- else }}
  {{- if .Values.jenkins.controller.ingress.hostName }}
    {{- if .Values.jenkins.controller.ingress.tls }}
      {{- default "https" .Values.jenkins.controller.jenkinsUrlProtocol }}://{{ .Values.jenkins.controller.ingress.hostName }}{{ default "" .Values.jenkins.controller.jenkinsUriPrefix }}
    {{- else }}
      {{- default "http" .Values.jenkins.controller.jenkinsUrlProtocol }}://{{ .Values.jenkins.controller.ingress.hostName }}{{ default "" .Values.jenkins.controller.jenkinsUriPrefix }}
    {{- end }}
  {{- else }}
      {{- default "http" .Values.jenkins.controller.jenkinsUrlProtocol }}://{{ template "jenkins.fullname" . }}:{{.Values.jenkins.controller.servicePort}}{{ default "" .Values.jenkins.controller.jenkinsUriPrefix }}
  {{- end}}
{{- end}}
{{- end -}}

{{/*
Returns kubernetes pod template configuration as code
*/}}
{{- define "jenkins.casc.podTemplate" -}}
- name: "{{ .Values.jenkins.agent.podName }}"
{{- if .Values.jenkins.agent.annotations }}
  annotations:
  {{- range $key, $value := .Values.jenkins.agent.annotations }}
  - key: {{ $key }}
    value: {{ $value | quote }}
  {{- end }}
{{- end }}
  id: {{ sha256sum (toYaml .Values.jenkins.agent) }}
  containers:
  - name: "{{ .Values.jenkins.agent.sideContainerName }}"
    alwaysPullImage: {{ .Values.jenkins.agent.alwaysPullImage }}
    args: "{{ .Values.jenkins.agent.args | replace "$" "^$" }}"
    command: {{ .Values.jenkins.agent.command }}
    envVars:
      - envVar:
          key: "JENKINS_URL"
          {{- if .Values.jenkins.agent.jenkinsUrl }}
          value: {{ tpl .Values.jenkins.agent.jenkinsUrl . }}
          {{- else }}
          value: "http://{{ template "jenkins.fullname" . }}.{{ template "jenkins.namespace" . }}.svc.{{.Values.jenkins.clusterZone}}:{{.Values.jenkins.controller.servicePort}}{{ default "/" .Values.jenkins.controller.jenkinsUriPrefix }}"
          {{- end }}
    image: "{{ .Values.jenkins.agent.image }}:{{ .Values.jenkins.agent.tag }}"
    privileged: "{{- if .Values.jenkins.agent.privileged }}true{{- else }}false{{- end }}"
    resourceLimitCpu: {{.Values.jenkins.agent.resources.limits.cpu}}
    resourceLimitMemory: {{.Values.jenkins.agent.resources.limits.memory}}
    resourceRequestCpu: {{.Values.jenkins.agent.resources.requests.cpu}}
    resourceRequestMemory: {{.Values.jenkins.agent.resources.requests.memory}}
    runAsUser: {{ .Values.jenkins.agent.runAsUser }}
    runAsGroup: {{ .Values.jenkins.agent.runAsGroup }}
    ttyEnabled: {{ .Values.jenkins.agent.TTYEnabled }}
    workingDir: {{ .Values.jenkins.agent.workingDir }}
{{- if .Values.jenkins.agent.envVars }}
  envVars:
  {{- range $index, $var := .Values.jenkins.agent.envVars }}
    - envVar:
        key: {{ $var.name }}
        value: {{ tpl $var.value $ }}
  {{- end }}
{{- end }}
  idleMinutes: {{ .Values.jenkins.agent.idleMinutes }}
  instanceCap: 2147483647
  {{- if .Values.jenkins.agent.imagePullSecretName }}
  imagePullSecrets:
  - name: {{ .Values.jenkins.agent.imagePullSecretName }}
  {{- end }}
  label: "{{ .Release.Name }}-{{ .Values.jenkins.agent.componentName }} {{ .Values.jenkins.agent.customJenkinsLabels  | join " " }}"
{{- if .Values.jenkins.agent.nodeSelector }}
  nodeSelector:
  {{- $local := dict "first" true }}
  {{- range $key, $value := .Values.jenkins.agent.nodeSelector }}
    {{- if $local.first }} {{ else }},{{ end }}
    {{- $key }}={{ tpl $value $ }}
    {{- $_ := set $local "first" false }}
  {{- end }}
{{- end }}
  nodeUsageMode: {{ quote .Values.jenkins.agent.nodeUsageMode }}
  podRetention: {{ .Values.jenkins.agent.podRetention }}
  showRawYaml: {{ .Values.jenkins.agent.showRawYaml }}
  serviceAccount: {{ default "default" .Values.jenkins.serviceAccountAgent.name }}
  slaveConnectTimeoutStr: "{{ .Values.jenkins.agent.connectTimeout }}"
{{- if .Values.jenkins.agent.volumes }}
  volumes:
  {{- range $index, $volume := .Values.jenkins.agent.volumes }}
    -{{- if (eq $volume.type "ConfigMap") }} configMapVolume:
     {{- else if (eq $volume.type "EmptyDir") }} emptyDirVolume:
     {{- else if (eq $volume.type "HostPath") }} hostPathVolume:
     {{- else if (eq $volume.type "Nfs") }} nfsVolume:
     {{- else if (eq $volume.type "PVC") }} persistentVolumeClaim:
     {{- else if (eq $volume.type "Secret") }} secretVolume:
     {{- else }} {{ $volume.type }}:
     {{- end }}
    {{- range $key, $value := $volume }}
      {{- if not (eq $key "type") }}
        {{ $key }}: {{ if kindIs "string" $value }}{{ tpl $value $ | quote }}{{ else }}{{ $value }}{{ end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.jenkins.agent.workspaceVolume }}
  workspaceVolume:
    {{- if (eq .Values.jenkins.agent.workspaceVolume.type "DynamicPVC") }}
    dynamicPVC:
    {{- else if (eq .Values.jenkins.agent.workspaceVolume.type "EmptyDir") }}
    emptyDirWorkspaceVolume:
    {{- else if (eq .Values.jenkins.agent.workspaceVolume.type "HostPath") }}
    hostPathWorkspaceVolume:
    {{- else if (eq .Values.jenkins.agent.workspaceVolume.type "Nfs") }}
    nfsWorkspaceVolume:
    {{- else if (eq .Values.jenkins.agent.workspaceVolume.type "PVC") }}
    persistentVolumeClaimWorkspaceVolume:
    {{- else }}
    {{ .Values.jenkins.agent.workspaceVolume.type }}:
    {{- end }}
  {{- range $key, $value := .Values.jenkins.agent.workspaceVolume }}
    {{- if not (eq $key "type") }}
      {{ $key }}: {{ if kindIs "string" $value }}{{ tpl $value $ | quote }}{{ else }}{{ $value }}{{ end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.jenkins.agent.yamlTemplate }}
  yaml: |-
    {{- tpl (trim .Values.jenkins.agent.yamlTemplate) . | nindent 4 }}
{{- end }}
  yamlMergeStrategy: {{ .Values.jenkins.agent.yamlMergeStrategy }}
{{- end -}}

{{/*
Returns configuration as code config
*/}}
{{- define "jenkins.casc.config" -}}
jenkins:
  {{- $configScripts := toYaml .Values.jenkins.controller.JCasC.configScripts }}
  disableRememberMe: {{ .Values.jenkins.controller.disableRememberMe }}
  mode: {{ .Values.jenkins.controller.executorMode }}
  numExecutors: {{ .Values.jenkins.controller.numExecutors }}
  {{- if not (kindIs "invalid" .Values.jenkins.controller.customJenkinsLabels) }}
  labelString: "{{ join " " .Values.jenkins.controller.customJenkinsLabels }}"
  {{- end }}
  projectNamingStrategy: "standard"
  markupFormatter:
    {{- if .Values.jenkins.controller.enableRawHtmlMarkupFormatter }}
    rawHtml:
      disableSyntaxHighlighting: true
    {{- else }}
    {{- toYaml .Values.jenkins.controller.markupFormatter | nindent 4 }}
    {{- end }}
  clouds:
  - kubernetes:
      containerCapStr: "{{ .Values.jenkins.agent.containerCap }}"
      defaultsProviderTemplate: "{{ .Values.jenkins.agent.defaultsProviderTemplate }}"
      connectTimeout: "{{ .Values.jenkins.agent.kubernetesConnectTimeout }}"
      readTimeout: "{{ .Values.jenkins.agent.kubernetesReadTimeout }}"
      {{- if .Values.jenkins.agent.jenkinsUrl }}
      jenkinsUrl: "{{ tpl .Values.jenkins.agent.jenkinsUrl . }}"
      {{- else }}
      jenkinsUrl: "http://{{ template "jenkins.fullname" . }}.{{ template "jenkins.namespace" . }}.svc.{{.Values.clusterZone}}:{{.Values.jenkins.controller.servicePort}}{{ default "" .Values.jenkins.controller.jenkinsUriPrefix }}"
      {{- end }}
      {{- if not .Values.jenkins.agent.websocket }}
      {{- if .Values.jenkins.agent.jenkinsTunnel }}
      jenkinsTunnel: "{{ tpl .Values.jenkins.agent.jenkinsTunnel . }}"
      {{- else }}
      jenkinsTunnel: "{{ template "jenkins.fullname" . }}-agent.{{ template "jenkins.namespace" . }}.svc.{{.Values.clusterZone}}:{{ .Values.jenkins.controller.agentListenerPort }}"
      {{- end }}
      {{- else }}
      webSocket: true
      {{- end }}
      maxRequestsPerHostStr: {{ .Values.jenkins.agent.maxRequestsPerHostStr | quote }}
      name: "{{ .Values.jenkins.controller.cloudName }}"
      namespace: {{ .Release.Namespace }}
      serverUrl: "https://kubernetes.default"
      {{- if .Values.jenkins.agent.enabled }}
      podLabels:
      - key: "jenkins/{{ .Release.Name }}-{{ .Values.jenkins.agent.componentName }}"
        value: "true"
      {{- range $key, $val := .Values.jenkins.agent.podLabels }}
      - key: {{ $key | quote }}
        value: {{ $val | quote }}
      {{- end }}
      templates:
      {{- include "jenkins.casc.podTemplate" . | nindent 8 }}
    {{- if .Values.additionalAgents }}
      {{- /* save .Values.jenkins.agent */}}
      {{- $agent := .Values.jenkins.agent }}
      {{- range $name, $additionalAgent := .Values.additionalAgents }}
        {{- /* merge original .Values.jenkins.agent into additional agent to ensure it at least has the default values */}}
        {{- $additionalAgent := merge $additionalAgent $agent }}
        {{- /* set .Values.jenkins.agent to $additionalAgent */}}
        {{- $_ := set $.Values "agent" $additionalAgent }}
        {{- include "jenkins.casc.podTemplate" $ | nindent 8 }}
      {{- end }}
      {{- /* restore .Values.jenkins.agent */}}
      {{- $_ := set .Values "agent" $agent }}
    {{- end }}
      {{- if .Values.jenkins.agent.podTemplates }}
        {{- range $key, $val := .Values.jenkins.agent.podTemplates }}
          {{- tpl $val $ | nindent 8 }}
        {{- end }}
      {{- end }}
      {{- end }}
  {{- if .Values.jenkins.controller.csrf.defaultCrumbIssuer.enabled }}
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: {{ if .Values.jenkins.controller.csrf.defaultCrumbIssuer.proxyCompatability }}true{{ else }}false{{- end }}
  {{- end }}
security:
  apiToken:
    creationOfLegacyTokenEnabled: false
    tokenGenerationOnCreationEnabled: false
    usageStatisticsEnabled: true
{{- if .Values.jenkins.controller.scriptApproval }}
  scriptApproval:
    approvedSignatures:
{{- range $key, $val := .Values.jenkins.controller.scriptApproval }}
    - "{{ $val }}"
{{- end }}
{{- end }}
unclassified:
  location:
    adminAddress: {{ default "" .Values.jenkins.controller.jenkinsAdminEmail }}
    url: {{ template "jenkins.url" . }}
{{- end -}}