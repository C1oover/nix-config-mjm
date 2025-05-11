{{ define "pagerduty.severity" }}{{ if eq .Status "firing" }}{{ if eq .CommonLabels.severity "notice" }}warning{{ else }}error{{ end }}{{ else }}warning{{ end }}{{ end }}

{{ define "pagerduty.instances" }}{{ range . }}{{ .Annotations.description }}

{{ $skipLabels := stringSlice "alertname" "__alert_rule_namespace_uid__" "__alert_rule_uid__" "grafana_folder" "severity" -}}
Labels:
{{ range (.Labels.Remove $skipLabels).SortedPairs }} - {{ .Name }} = {{ .Value }}
{{ end }}
Source: {{ .GeneratorURL }}
{{ end }}{{ end }}
