{{- define "node-exporter.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "node-exporter.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
