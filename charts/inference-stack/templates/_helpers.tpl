{{/*
Expand the name of the chart.
*/}}
{{- define "inference-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "inference-stack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "inference-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "inference-stack.labels" -}}
helm.sh/chart: {{ include "inference-stack.chart" . }}
{{ include "inference-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "inference-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "inference-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "inference-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "inference-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Set env vars for inference-stack gateway */}}
{{- define "inference-stack.gatewayEnv" -}}

{{/* Set the required env vars needed for each application deployment */}}
{{- $requiredEnv := dict }}
{{- $_ := set $requiredEnv "TAKEOFF_ADD_READER_ID_SUFFIX" (dict "value" "true") }}

{{/* Convert user set env vars into dict */}}
{{- $userEnv := dict }}
{{- range $envMap := .Values.gateway.env }}
{{- if hasKey $envMap "value" }}
    {{- $_ := set $userEnv $envMap.name (dict "value" $envMap.value) }}
{{ else if hasKey $envMap "valueFrom" }}
    {{- $_ := set $userEnv $envMap.name (dict "valueFrom" $envMap.valueFrom) }}
{{- end }}
{{- end }}

{{/* Define the list to hold the env */}}
{{- $applicationEnv := list }}
{{/* Merge the template env with user env. Lets users overwrite default values. */}}
{{- $applicationEnvDict := merge $requiredEnv $userEnv }}

{{/* Loop through the merged env and append to the list */}}
{{- range $key, $value := $applicationEnvDict }}
    {{- if $value.value }}
        {{- $applicationEnv = append $applicationEnv (dict "name" $key "value" $value.value) }}
    {{- else if $value.valueFrom }}
        {{- $applicationEnv = append $applicationEnv (dict "name" $key "valueFrom" $value.valueFrom) }}
    {{- end }}
{{- end }}

{{- $applicationEnv | toYaml }}
{{- end }}