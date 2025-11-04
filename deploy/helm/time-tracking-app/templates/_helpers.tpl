{{/*
Expand the name of the chart.
If .Values.nameOverride is set, prefer that; otherwise use .Chart.Name.
*/}}
{{- define "time-tracking-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
If .Values.fullnameOverride is set, prefer that.
Falls back to <release-name>-<name>.
*/}}
{{- define "time-tracking-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "time-tracking-app.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart label, e.g., time-tracking-app-0.1.0
*/}}
{{- define "time-tracking-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels applied to most resources.
*/}}
{{- define "time-tracking-app.labels" -}}
app.kubernetes.io/name: {{ include "time-tracking-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Chart.Version | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "time-tracking-app.chart" . }}
{{- end -}}

{{/*
Selector labels used by Deployment.spec.selector.matchLabels and Pod template labels.
Keep these stable to avoid unintended rollouts.
*/}}
{{- define "time-tracking-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "time-tracking-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Derive the ServiceAccount name.
If .Values.serviceAccount.create is true and .Values.serviceAccount.name is empty,
use the fullname. If create=false, use "default".
*/}}
{{- define "time-tracking-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "time-tracking-app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
default
{{- end -}}
{{- end -}}
