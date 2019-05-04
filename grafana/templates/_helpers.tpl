{{- define "grafana.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "grafana.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
