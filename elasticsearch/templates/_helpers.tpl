{{- define "elasticsearch.release_labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "elasticsearch.full_name" -}}
{{- .Values.appName -}}
{{- end -}}

{{- define "endpoints" -}}
{{- $replicas := .replicas | int }}
{{- $np := printf "%s" .nodePrefix }}
  {{- range $i := untilStep 0 $replicas 1 -}}
{{ $np }}-{{ $i }},
  {{- end -}}
{{- end -}}