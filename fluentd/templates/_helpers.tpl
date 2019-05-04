{{- define "fluentd.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "fluentd.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
