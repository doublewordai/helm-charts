{{/*
Expand the name of the chart.
*/}}
{{- define "observability.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
This value is used to prefix sub-apps. We use the just release name for brevity, unless there is an override.
*/}}
{{- define "observability.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "observability.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "observability.labels" -}}
helm.sh/chart: {{ include "observability.chart" . }}
{{ include "observability.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "observability.name" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "observability.selectorLabels" -}}
app.kubernetes.io/name: {{ include "observability.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
