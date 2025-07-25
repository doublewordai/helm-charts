{{/*
Expand the name of the chart.
*/}}
{{- define "console.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
This value is used to prefix sub-apps. We use the just release name for brevity, unless there is an override.
*/}}
{{- define "console.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "console.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "console.labels" -}}
helm.sh/chart: {{ include "console.chart" . }}
{{ include "console.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "console.selectorLabels" -}}
app.kubernetes.io/name: {{ include "console.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "console.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "console.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}{{/*
*/}}

{{/*
Defines the tailscale hostname
*/}}
{{- define "console.tailscale" -}}
{{- printf "%s-%s" (include "console.fullname" .) .Release.Namespace  | quote }}
{{- end }}

{{/* 
Define the name of the InferenceStack CR created with this chart to be referred to in many places
*/}}
{{- define "console.inferenceStackCRName" -}}
{{- printf "%s-stack" (include "console.fullname" $) | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* 
Create Backend Environment Variables for Zeus 
*/}}
{{- define "console.zeusBackendEnv" -}}

{{/* 
Create a template for necessary environment variables for Zeus backend 
*/}}
{{- $templateEnv := dict }}
{{- $_ := set $templateEnv "ZEUS_DROP_TABLES_ON_INIT" (dict "value" "False") }}
{{- $_ := set $templateEnv "ZEUS_DB_HOST" (dict "value" (printf "%s-db" (include "console.fullname" .))) }}
{{- $_ := set $templateEnv "ZEUS_DB_PORT" (dict "value" "5432") }}
{{- $_ := set $templateEnv "ZEUS_DB_NAME" (dict "value" "zeus") }}
{{- $_ := set $templateEnv "ZEUS_INFERENCE_STACK_CR_NAME" (dict "value" ( include "console.inferenceStackCRName" $ )) }}
{{- $_ := set $templateEnv "ZEUS_CLUSTER_NAMESPACE" (dict "value" .Release.Namespace) }}
{{- $_ := set $templateEnv "ZEUS_ENABLE_NATS" (dict "value" "True") }}
{{- $_ := set $templateEnv "ZEUS_NATS_URL" (dict "value" (printf "nats://%s-events:4222" (include "console.fullname" .))) }}

{{/* 
Convert user set env vars into dict 
*/}}
{{- $userEnv := dict }}
{{- range $envMap := .Values.backend.env }}
{{- if hasKey $envMap "value" }}
    {{- $_ := set $userEnv $envMap.name (dict "value" $envMap.value) }}
{{ else if hasKey $envMap "valueFrom" }}
    {{- $_ := set $userEnv $envMap.name (dict "valueFrom" $envMap.valueFrom) }}
{{- end }}
{{- end }}

{{/* 
Define the list to hold the env 
*/}}
{{- $zeusBackendEnv := list }}
{{/* Merge the template env with user env. Lets users overwrite default values. */}}
{{- $zeusBackendEnvDict := merge $userEnv $templateEnv }}

{{/* 
Loop through the merged env and append to the list 
*/}}
{{- range $key, $value := $zeusBackendEnvDict }}
    {{- if $value.value }}
        {{- $zeusBackendEnv = append $zeusBackendEnv (dict "name" $key "value" $value.value) }}
    {{- else if $value.valueFrom }}
        {{- $zeusBackendEnv = append $zeusBackendEnv (dict "name" $key "valueFrom" $value.valueFrom) }}
    {{- end }}
{{- end }}

{{- $zeusBackendEnv | toYaml }}
{{- end }}

{{/* 
Create Frontend Environment Variables for Zeus 
*/}}
{{- define "console.zeusFrontendEnv" -}}

{{- $templateEnv := dict }}
{{- $backendPort := int (.Values.backend.service.port | default 80) }}
{{- $_ := set $templateEnv "BACKEND_API_DESTINATION" (dict "value" (printf "http://%s-backend:%d" (include "console.fullname" .) $backendPort)) }}
{{- $_ := set $templateEnv "BACKEND_GATEWAY_DESTINATION" (dict "value" (printf "http://%s-gateway:%d" (include "console.inferenceStackCRName" $) 80)) }}

{{/* 
Convert env vars into dict 
*/}}
{{- $userEnv := dict }}
{{- range $envMap := .Values.frontend.env }}
{{- if hasKey $envMap "value" }}
    {{- $_ := set $userEnv $envMap.name (dict "value" $envMap.value) }}
{{ else if hasKey $envMap "valueFrom" }}
    {{- $_ := set $userEnv $envMap.name (dict "valueFrom" $envMap.valueFrom) }}
{{- end }}
{{- end }}

{{/* Define the list to hold the env */}}
{{- $zeusFrontendEnv := list }}
{{/* Merge the template env with user env. Lets users overwrite default values. */}}
{{- $zeusFrontendEnvDict := merge $userEnv $templateEnv }}

{{/* Loop through the merged env and append to the list */}}
{{- range $key, $value := $zeusFrontendEnvDict }}
    {{- if $value.value }}
        {{- $zeusFrontendEnv = append $zeusFrontendEnv (dict "name" $key "value" $value.value) }}
    {{- else if $value.valueFrom }}
        {{- $zeusFrontendEnv = append $zeusFrontendEnv (dict "name" $key "valueFrom" $value.valueFrom) }}
    {{- end }}
{{- end }}

{{- $zeusFrontendEnv | toYaml }}
{{- end }}


{{/* ---------- zeusSatelliteEnv ------------------------------ */}}

{{- if and (not .Values.cluster.leader) .Values.cluster.interconnect.enabled }}
  {{- required "ERROR: in follower mode you must set cluster.satellite.centralRelease or BOTH centralBackendHost and centralGatewayHost" 
      (or .Values.cluster.satellite.centralRelease 
          (and .Values.cluster.satellite.centralBackendHost .Values.cluster.satellite.centralGatewayHost)) }}
{{- end }}

{{/* ---------- CENTRAL-SITE HOST (no scheme / port) ---------- */}}
{{- define "console.centralHost" }}
  {{- if .Values.cluster.leader }}
    {{- /* leader always uses its own backend */ -}}
    {{- printf "%s-backend" (include "console.fullname" .) }}
  {{- else }}
    {{- /* follower: first try a custom override */ -}}
    {{- $custom := .Values.cluster.satellite.centralBackendHost | default "" }}
    {{- if ne $custom "" }}
      {{- $custom }}
    {{- else }}
      {{- /* next fall back to centralRelease if set */ -}}
      {{- $rel := .Values.cluster.satellite.centralRelease | default "" }}
      {{- if ne $rel "" }}
        {{- printf "%s-backend" $rel }}
      {{- else }}
        {{- /* finally error if neither is provided */ -}}
        {{- required "ERROR: in follower mode you must set cluster.satellite.centralRelease or centralBackendHost" .Values.cluster.satellite.centralRelease }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* ---------- CENTRAL-SITE PORT ---------------------------- */}}
{{- define "console.centralPort" -}}
  {{- /* Leader always use backend svc port, otherwise if interconnect on use its port */ -}}
  {{- if .Values.cluster.leader -}}
    {{- int (default 80 .Values.backend.service.port) -}}
  {{- else if .Values.cluster.interconnect.enabled -}}
    {{- int .Values.cluster.interconnect.port -}}
  {{- else -}}
    {{- int (default 80 .Values.backend.service.port) -}}
  {{- end -}}
{{- end }}

{{/* ---------- FULL CENTRAL URL (scheme://host:port) --------- */}}
{{- define "console.centralURL" -}}
  {{- $host := include "console.centralHost" . -}}
  {{- $port := include "console.centralPort" . | int -}}
  {{- printf "http://%s:%d" $host $port -}}
{{- end }}

{{- define "console.zeusSatelliteEnv" -}}
{{- $templateEnv := dict }}

{{/* ---------- ZEUS_NAME ------------------------------------- */}}
{{- if .Values.cluster.leader }}
  {{- $_ := set $templateEnv "ZEUS_NAME" (dict "value" (default .Release.Name .Values.cluster.name)) }}
{{- else }}
  {{- $_ := set $templateEnv "ZEUS_NAME" (dict "value" (required "ERROR: cluster.name is required for follower mode" .Values.cluster.name)) }}
{{- end }}

{{/* ---------- ZEUS_CLUSTER_NAMESPACE ----------------------- */}}
{{- $_ := set $templateEnv "ZEUS_CLUSTER_NAMESPACE" (dict "value" .Release.Namespace) }}

{{/* ---------- ZEUS_INFERENCE_STACK_CR_NAME ------------------ */}}
{{- $_ := set $templateEnv "ZEUS_INFERENCE_STACK_CR_NAME" (dict "value" (include "console.inferenceStackCRName" .)) }}

{{/* ---------- ZEUS_PROVIDER -------------------------------- */}}
{{- if .Values.cluster.satellite.provider }}
  {{- $_ := set $templateEnv "ZEUS_PROVIDER" (dict "value" .Values.cluster.satellite.provider) }}
{{- end }}

{{/* ---------- ZEUS_CENTRAL_BASE_URL ------------------------ */}}
{{- $_ := set $templateEnv "ZEUS_CENTRAL_BASE_URL"
     (dict "value" (include "console.centralURL" .)) }}

{{- /* ZEUS_CENTRAL_GATEWAY_HOST & PORT */ -}}
{{- $gwHost := "" -}}
{{- if .Values.cluster.leader -}}
  {{- /* leader always points at its own gateway */ -}}
  {{- $gwHost = printf "%s-stack-gateway" (include "console.fullname" .) -}}
{{- else -}}
  {{- /* follower: prefer an explicit override */ -}}
  {{- if .Values.cluster.satellite.centralGatewayHost -}}
    {{- $gwHost = .Values.cluster.satellite.centralGatewayHost -}}
  {{- else -}}
    {{- $gwHost = printf "%s-stack-gateway" .Values.cluster.satellite.centralRelease -}}
  {{- end -}}
{{- end -}}
{{- $_ := set $templateEnv "ZEUS_CENTRAL_GATEWAY_HOST" (dict "value" $gwHost) -}}
{{- $_ := set $templateEnv "ZEUS_CENTRAL_GATEWAY_PORT" (dict "value" "3005") -}}

{{- /* merge user-supplied */}}
{{- $userEnv := dict }}
{{- range $e := .Values.cluster.satellite.env }}
  {{- if hasKey $e "value" }}
    {{- $_ := set $userEnv $e.name (dict "value" $e.value) }}
  {{- else if hasKey $e "valueFrom" }}
    {{- $_ := set $userEnv $e.name (dict "valueFrom" $e.valueFrom) }}
  {{- end }}
{{- end }}

{{- /* assemble final list */}}
{{- $envDict := merge $templateEnv $userEnv }}
{{- $envList := list }}
{{- range $k, $v := $envDict }}
  {{- if $v.value }}
    {{- $envList = append $envList (dict "name" $k "value" $v.value) }}
  {{- else if $v.valueFrom }}
    {{- $envList = append $envList (dict "name" $k "valueFrom" $v.valueFrom) }}
  {{- end }}
{{- end }}
{{- toYaml $envList }}
{{- end }}
