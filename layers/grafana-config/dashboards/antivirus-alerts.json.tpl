{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": false,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 37,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "P1809F7CD0C75ACF3"
            },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
            },
          "custom": {
            "axisLabel": "Infected Files",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "line+area"
            }
          },
          "decimals": 0,
          "links": [
          {
              "title": "",
              "url": ""
            }
              ],
          "mappings": [],
          "max": 10,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-green",
                "value": null
            },
              {
                "color": "red",
                "value": 1
              }
              ]
            },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "links": [
        {
          "targetBlank": true,
          "title": "Insights list of hosts, files, and signatures ",
          "url": "https://${region}.console.${aws_base_domain}/cloudwatch/home?region=${region}#dashboards:name=${dashboard_name};expand=true"
        },
        {
          "targetBlank": true,
          "title": "Cloudwatch Logs query for ' FOUND\\\"'",
          "url": "https://${region}.console.${aws_base_domain}/cloudwatch/home?region=${region}#logsV2:log-groups/log-group/${log_group_name}/log-events$3FfilterPattern$3D$2522+FOUND$255C$2522$2522"
        }
      ],
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "hidden",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single",
          "sort": "desc"
          }
      },
      "pluginVersion": "8.5.2",
      "targets": [
        {
          "expr": " fluentd_clamav_infected_files unless on (source_address) (label_join(system_healthy{origin=\"system_metrics_agent\"}, \"source_address\", \"\", \"ip\") < 1)",
          "interval": "",
          "legendFormat": "{{source_address}}",
          "refId": "A"
        },
        {
          "expr": " fluentd_clamav_infected_files unless on (source_address) (label_replace(up{job=\"ec2\"}, \"source_address\", \"$1\", \"instance\", \"(.*):.*\") < 1)",
          "interval": "",
          "legendFormat": "{{source_address}}",
          "refId": "C"
        },
        {
          "expr": "fluentd_clamav_infected_files",
          "hide": true,
          "interval": "",
          "legendFormat": "",
          "refId": "B"
        }
      ],
      "title": "AntiVirus Detections",
      "transparent": true,
      "type": "timeseries"
      },
        {
      "datasource": {
        "type": "loki",
        "uid": "twsLokiDataSource"
      },
      "gridPos": {
        "h": 20,
        "w": 24,
        "x": 0,
        "y": 9
      },
      "id": 4,
      "options": {
        "dedupStrategy": "none",
        "enableLogDetails": true,
        "prettifyLogMessage": false,
        "showCommonLabels": false,
        "showLabels": false,
        "showTime": false,
        "sortOrder": "Descending",
        "wrapLogMessage": false
        },
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "twsLokiDataSource"
          },
          "expr": "{ident=\"antivirus\"} |= \"FOUND\" | json | line_format \"{{.source_address}} {{.message}}\"",
          "legendFormat": "",
          "queryType": "range",
          "refId": "A"
        }
      ],
      "title": "AntiVirus Detection Logs",
      "transparent": true,
      "type": "logs"
    }
  ],
  "refresh": "10s",
  "schemaVersion": 36,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-24h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "browser",
  "title": "ClamAV Virus Detections",
  "uid": "RLGLyeeZz",
  "version": 12
}
