{{- define "kibana.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "kibana.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
