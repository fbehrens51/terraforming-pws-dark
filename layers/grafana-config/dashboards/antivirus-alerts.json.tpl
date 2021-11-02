{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": false,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 29,
  "links": [],
  "panels": [
    {
      "alert": {
        "alertRuleTags": {},
        "conditions": [
          {
            "evaluator": {
              "params": [
                0
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A",
                "1m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "max"
            },
            "type": "query"
          },
          {
            "evaluator": {
              "params": [
                0
              ],
              "type": "gt"
            },
            "operator": {
              "type": "or"
            },
            "query": {
              "params": [
                "B",
                "1m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "max"
            },
            "type": "query"
          }
        ],
        "executionErrorState": "keep_state",
        "for": "1m",
        "frequency": "1m",
        "handler": 1,
        "message": "A virus was detected!",
        "name": "AntiVirus Infections found alert",
        "noDataState": "keep_state",
        "notifications": []
      },
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
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
      "nullPointMode": "null as zero",
      "options": {
        "dataLinks": [
          {
            "title": "",
            "url": ""
          }
        ]
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
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
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "gt",
          "value": 0,
          "yaxis": "left"
        }
      ],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "AntiVirus Infections",
      "tooltip": {
        "shared": true,
        "sort": 2,
        "value_type": "individual"
      },
      "transparent": true,
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "decimals": 0,
          "format": "short",
          "label": "Infected Files",
          "logBase": 1,
          "max": "10",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": "10s",
  "schemaVersion": 25,
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
  "version": 11
}
