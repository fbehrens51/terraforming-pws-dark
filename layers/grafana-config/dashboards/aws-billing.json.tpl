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
  "description": "Visualize estimated AWS charges per AWS resource (EC2, S3, ...)",
  "editable": false,
  "fiscalYearStartMonth": 0,
  "gnetId": 139,
  "graphTooltip": 1,
  "id": 79,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "cloudwatch",
        "uid": "$datasource"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
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
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "currencyUSD"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 15,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "sortBy": "Max",
          "sortDesc": true
        },
        "tooltip": {
          "mode": "multi",
          "sort": "desc"
        }
      },
      "pluginVersion": "9.0.6",
      "targets": [
        {
          "alias": "Total",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "Currency": "USD"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "highResolution": false,
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "Total",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "EstimatedCharges",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/Billing",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$billingRegion",
          "returnData": false,
          "sqlExpression": "",
          "statistic": "Average"
        },
        {
          "alias": "{{ServiceName}}",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "Currency": "USD",
            "ServiceName": "*"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "highResolution": false,
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${PROP('Dim.ServiceName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "EstimatedCharges",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/Billing",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$billingRegion",
          "returnData": false,
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "Estimated charges",
      "transparent": true,
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "cloudwatch",
        "uid": "$datasource"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
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
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "currencyUSD"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 10,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 3,
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi",
          "sort": "desc"
        }
      },
      "pluginVersion": "9.0.6",
      "targets": [
        {
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "Currency": "USD"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "hide": true,
          "highResolution": false,
          "host": {
            "filter": ""
          },
          "id": "m1",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "EstimatedCharges",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/Billing",
          "options": {
            "showDisabledItems": false
          },
          "period": "86400",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$billingRegion",
          "returnData": false,
          "sqlExpression": "",
          "statistic": "Average"
        },
        {
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "Currency": "USD"
          },
          "expression": "RATE(m1) * PERIOD(m1)",
          "functions": [],
          "group": {
            "filter": ""
          },
          "hide": true,
          "highResolution": false,
          "host": {
            "filter": ""
          },
          "id": "m2",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 1,
          "metricName": "EstimatedCharges",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/Billing",
          "options": {
            "showDisabledItems": false
          },
          "period": "86400",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$billingRegion",
          "returnData": false,
          "sqlExpression": "",
          "statistic": "Average"
        },
        {
          "alias": "Total estimated daily charge",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "Currency": "USD"
          },
          "expression": "IF(m2>0, m2)",
          "functions": [],
          "group": {
            "filter": ""
          },
          "hide": false,
          "highResolution": false,
          "host": {
            "filter": ""
          },
          "id": "m3",
          "item": {
            "filter": ""
          },
          "label": "Total estimated daily charge",
          "matchExact": true,
          "metricEditorMode": 1,
          "metricName": "EstimatedCharges",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/Billing",
          "options": {
            "showDisabledItems": false
          },
          "period": "86400",
          "queryMode": "Metrics",
          "refId": "C",
          "region": "$billingRegion",
          "returnData": false,
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "Estimated daily charges",
      "transparent": true,
      "type": "timeseries"
    }
  ],
  "refresh": false,
  "schemaVersion": 36,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": [
      {
        "current": {
          "selected": false,
          "text": "cloudwatch",
          "value": "cloudwatch"
        },
        "hide": 0,
        "includeAll": false,
        "label": "Datasource",
        "multi": false,
        "name": "datasource",
        "options": [],
        "query": "cloudwatch",
        "queryValue": "",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "type": "datasource"
      },
      {
        "description": "All billing data is stored in us-east-1 for commercial regions.",
        "hide": 2,
        "label": "Billing Region",
        "name": "billingRegion",
        "query": "${billing_region}",
        "skipUrlSync": false,
        "type": "constant"
      }
    ]
  },
  "time": {
    "from": "now-30d",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "browser",
  "title": "AWS Billing",
  "uid": "AWSBillig",
  "version": 6,
  "weekStart": ""
}
