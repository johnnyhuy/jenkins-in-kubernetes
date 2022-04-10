{{/*
Returns Jenkins configuration as code 
wherever the Jenkins controller URL is required
since source of truth is set in Helm chart values at `jenkins.controller.jenkinsUrl`

jenkins:
  ...
unclassified:
  ...
  location:
    url: https://example-jenkins.com:8080
*/}}
{{- define "jenkins.casc.url" -}}
unclassified:
  location:
    adminAddress: 
    url: {{ .Values.jenkins.controller.jenkinsUrl }}
{{ end }}

{{/*
Returns Jenkins Kubernetes configuration as code

jenkins:
  clouds:
    - kubernetes:
        containerCapStr: "10"
        ...
        templates:
          - name: "default"
            ...
*/}}
{{- define "jenkins.casc.kubernetes" -}}
jenkins:
  clouds:
  - kubernetes:
      namespace: {{ .Release.Namespace }}
      jenkinsUrl: {{ .Values.jenkins.agent.jenkinsUrl }}
      jenkinsTunnel: "{{ template "jenkins.fullname" . }}-agent:{{.Values.jenkins.controller.agentListenerPort}}"
      serverUrl: "https://kubernetes.default"
      {{- toYaml .Values.jenkins.kubernetes | nindent 6 }}
      {{- if .Values.jenkins.agents }}
      templates:
        {{- range $name, $agent := .Values.jenkins.agents }}
        - name: {{ $name }}
          containers:
          {{- range $container := $agent.containers }}
          - name: "jnlp"
            alwaysPullImage: {{ default false $container.alwaysPullImage }}
            args: {{ default "${computer.jnlpmac} ${computer.name}" $container.args | replace "$" "^$" | quote }}
            command: {{ $container.command | quote }}
            envVars:
              - envVar:
                  key: "JENKINS_URL"
                  value: "{{ $.Values.jenkins.agent.jenkinsUrl }}/"
              {{- range $envVar := $container.envVars }}
              {{- toYaml $envVar }}
              {{- end }}
            image: {{ default "jenkins/inbound-agent:4.11.2-4" $container.image }}
            privileged: {{ default "false" $container.privileged }}
            resourceLimitCpu: {{ default "512m" $container.resourceLimitCpu }}
            resourceLimitMemory: {{ default "512Mi" $container.resourceLimitMemory }}
            resourceRequestCpu: {{ default "512m" $container.resourceRequestCpu }}
            resourceRequestMemory: {{ default "512Mi" $container.resourceRequestMemory }}
            ttyEnabled: {{ default "false" $container.ttyEnabled }}
            workingDir: {{ default "/home/jenkins/agent" $container.workingDir }}
          {{- end }}
          idleMinutes: {{ default "0" $agent.idleMinutes }}
          instanceCap: {{ default "2147483647" $agent.instanceCap }}
          label: {{ default "gradle" $agent.label }}
          nodeUsageMode: {{ default "EXCLUSIVE" $agent.nodeUsageMode }}
          podRetention: {{ default "Never" $agent.podRetention }}
          showRawYaml: {{ default "true" $agent.showRawYaml }}
          serviceAccount: {{ default "default" $agent.serviceAccount }}
          slaveConnectTimeoutStr: {{ default "100" $agent.slaveConnectTimeoutStr }}
          yamlMergeStrategy: {{ default "override" $agent.yamlMergeStrategy }}
        {{ end }}
      {{ end }}
{{ end }}