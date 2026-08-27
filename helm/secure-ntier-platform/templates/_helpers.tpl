{{/*
Shared template helpers for the secure-ntier-platform chart.
*/}}

{{- define "secure-ntier-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secure-ntier-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "secure-ntier-platform.name" . }}
{{- end }}
{{- end }}

{{- define "secure-ntier-platform.labels" -}}
app.kubernetes.io/name: {{ include "secure-ntier-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: secure-ntier
{{- end }}

{{- define "secure-ntier-platform.image" -}}
{{- $registry := .Values.image.registry | trimSuffix "/" -}}
{{- $tag := or .tag .Values.image.tag .Chart.AppVersion -}}
{{- if $registry -}}
{{ printf "%s/%s:%s" $registry .repository $tag }}
{{- else -}}
{{ printf "%s:%s" .repository $tag }}
{{- end -}}
{{- end }}
