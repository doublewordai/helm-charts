{{/*
Expand the name of the chart.
*/}}
{{- define "onwards.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
This value is used to prefix sub-apps. We use the just release name for brevity, unless there is an override.
*/}}
{{- define "onwards.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "onwards.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "onwards.labels" -}}
helm.sh/chart: {{ include "onwards.chart" . }}
{{ include "onwards.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "onwards.name" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "onwards.selectorLabels" -}}
app.kubernetes.io/name: {{ include "onwards.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
