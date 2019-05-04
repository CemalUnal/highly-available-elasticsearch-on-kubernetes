{{- define "kube-state-metrics.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "kube-state-metrics.full_name" -}}
{{- .Values.appName -}}
{{- end -}}
