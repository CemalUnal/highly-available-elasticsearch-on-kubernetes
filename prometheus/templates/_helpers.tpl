{{- define "prometheus.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "prometheus.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
