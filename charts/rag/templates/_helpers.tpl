{{/*
Expand the name of the chart.
*/}}
{{- define "rag.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
This value is used to prefix sub-apps. We use the just release name for brevity, unless there is an override.
*/}}
{{- define "rag.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rag.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rag.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rag.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rag.labels" -}}
helm.sh/chart: {{ include "rag.chart" . }}
{{ include "rag.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* 
Internal Database Name
*/}}
{{- define "rag.internalDbName" -}}
# loop over env vars
{{- $return := "" }}
{{- range $envMap := .Values.env }}
{{- if eq $envMap.name "INTERNAL_DB_NAME" }}
{{- $return := $envMap.name }}
{{- end }}
{{- end }}

{{- if eq $return "" }}
{{- $return := (printf "%s-postgres" (include "rag.fullname" .)) }}
{{- end }}

{{- $return | quote }}
{{- end }}

{{/* 
Create Backend Environment Variables for Zeus 
*/}}
{{- define "rag.BackendEnv" -}}

{{/* 
Create a template for necessary environment variables for Zeus backend 
*/}}
{{- $templateEnv := dict }}
{{- $_ := set $templateEnv "APP_PASSWORD" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.appPassword))) }}
{{- $_ := set $templateEnv "APP_USERNAME" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.appUsername))) }}
{{- $_ := set $templateEnv "GITHUB_TOKEN" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.githubToken))) }}
{{- $_ := set $templateEnv "MONGODB_PASSWORD" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.mongoDbPassword))) }}
{{- $_ := set $templateEnv "MONGODB_CONNECTION_STRING" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.mongoDbConnectionString))) }}
{{- $_ := set $templateEnv "MONGODB_FEEDBACK_DATABASE_NAME" (dict "value" (printf "%s-feedback" (include "rag.fullname" .))) }}
{{- $_ := set $templateEnv "INTERNAL_DATABASE_PASSWORD" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.internalDbPassword))) }}
{{- $_ := set $templateEnv "INTERNAL_DATABASE_USER" (dict "valueFrom" (dict "secretKeyRef" (dict "name" .Values.secret.name "key" .Values.secret.keys.internalDbUser))) }}
{{- $_ := set $templateEnv "INTERNAL_DATABASE_HOST" (dict "value" (printf "%s-postgres" (include "rag.fullname" .))) }}
{{- $_ := set $templateEnv "FEEDBACK_EXPORT_INTERVAL" (dict "value" (printf "%s-postgres" (include "rag.fullname" .))) }}

{{/* 
Convert user set env vars into dict 
*/}}
{{- $userEnv := dict }}
{{- range $envMap := .Values.env }}
{{- if hasKey $envMap "value" }}
    {{- $_ := set $userEnv $envMap.name (dict "value" $envMap.value) }}
{{ else if hasKey $envMap "valueFrom" }}
    {{- $_ := set $userEnv $envMap.name (dict "valueFrom" $envMap.valueFrom) }}
{{- end }}
{{- end }}

{{/* 
Define the list to hold the env 
*/}}
{{- $BackendEnv := list }}
{{/* Merge the template env with user env. Lets users overwrite default values. */}}
{{- $BackendEnvDict := merge $userEnv $templateEnv }}

{{/* 
Loop through the merged env and append to the list 
*/}}
{{- range $key, $value := $BackendEnvDict }}
    {{- if $value.value }}
        {{- $BackendEnv = append $BackendEnv (dict "name" $key "value" $value.value) }}
    {{- else if $value.valueFrom }}
        {{- $BackendEnv = append $BackendEnv (dict "name" $key "valueFrom" $value.valueFrom) }}
    {{- end }}
{{- end }}

{{- $BackendEnv | toYaml }}
{{- end }}