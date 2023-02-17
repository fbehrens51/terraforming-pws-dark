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
  "description": "Visualize AWS RDS metrics",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "gnetId": 707,
  "graphTooltip": 1,
  "id": 80,
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
          "noValue": "0",
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
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 16,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "hide": false,
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${LABEL} $${PROP('MetricName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "CPUUtilization",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "CPUUtilization",
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
          "noValue": "0",
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
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 7
      },
      "id": 18,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "DatabaseConnections",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Maximum"
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "DiskQueueDepth",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "DatabaseConnections/DiskQueueDepth",
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
          "noValue": "0",
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
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 14
      },
      "id": 17,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "FreeableMemory",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "FreeStorageSpace",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "FreeableMemory/FreeStorageSpace",
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
          "noValue": "0",
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
          "unit": "iops"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 21
      },
      "id": 19,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "ReadIOPS",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "WriteIOPS",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "ReadIOPS/WriteIOPS",
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
          "noValue": "0",
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
          "unit": "s"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 29
      },
      "id": 20,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "ReadLatency",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "WriteLatency",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "ReadLatency/WriteLatency",
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
          "noValue": "0",
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
          "unit": "Bps"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 36
      },
      "id": 21,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "ReadThroughput",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "WriteThroughput",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "ReadThroughput/WriteThroughput",
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
          "noValue": "0",
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
          "unit": "Bps"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 43
      },
      "id": 22,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "NetworkReceiveThroughput",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "NetworkTransmitThroughput",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "NetworkReceiveThroughput/NetworkTransmitThroughput",
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
          "noValue": "0",
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
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 50
      },
      "id": 23,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "SwapUsage",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "BinLogDiskUsage",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "SwapUsage/BinLogDiskUsage",
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
          "noValue": "0",
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
          "unit": "decmbytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 57
      },
      "id": 25,
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
          "placement": "right"
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${PROP('Dim.DBInstanceIdentifier')} $${PROP('MetricName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "OldestReplicationSlotLag",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${PROP('Dim.DBInstanceIdentifier')} $${PROP('MetricName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "ReplicaLag",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "OldestReplicationSlotLag/ReplicaLag",
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
          "noValue": "0",
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
          "unit": "decmbytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 64
      },
      "id": 26,
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
          "placement": "right"
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${PROP('Dim.DBInstanceIdentifier')} $${PROP('MetricName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "OldestReplicationSlotLag",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "$${PROP('Dim.DBInstanceIdentifier')} $${PROP('MetricName')}",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "ReplicaLag",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "ReplicationSlotDiskUsage/TransactionLogsDiskUsage",
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
          "noValue": "0",
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
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 71
      },
      "id": 27,
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
          "placement": "right",
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
          "alias": "",
          "application": {
            "filter": ""
          },
          "datasource": {
            "uid": "$datasource"
          },
          "dimensions": {
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "MaximumUsedTransactionIDs",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "A",
          "region": "$region",
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
            "DBInstanceIdentifier": "$dbinstanceidentifier"
          },
          "expression": "",
          "functions": [],
          "group": {
            "filter": ""
          },
          "host": {
            "filter": ""
          },
          "id": "",
          "item": {
            "filter": ""
          },
          "label": "",
          "matchExact": true,
          "metricEditorMode": 0,
          "metricName": "TransactionLogsGeneration",
          "metricQueryType": 0,
          "mode": 0,
          "namespace": "AWS/RDS",
          "options": {
            "showDisabledItems": false
          },
          "period": "",
          "queryMode": "Metrics",
          "refId": "B",
          "region": "$region",
          "sqlExpression": "",
          "statistic": "Average"
        }
      ],
      "title": "MaximumUsedTransactionIDs/TransactionLogsGeneration",
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
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "type": "datasource"
      },
      {
        "hide": 2,
        "label": "Region",
        "name": "region",
        "query": "${region}",
        "skipUrlSync": false,
        "type": "constant"
      },
      {
        "current": {
          "selected": true,
          "text": [
            "All"
          ],
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "uid": "$datasource"
        },
        "definition": "",
        "hide": 0,
        "includeAll": true,
        "label": "DBInstanceIdentifier",
        "multi": true,
        "name": "dbinstanceidentifier",
        "options": [],
        "query": "dimension_values($region, AWS/RDS, CPUUtilization, DBInstanceIdentifier)",
        "refresh": 1,
        "regex": "/$${env_name}.*/",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "hide": 2,
        "name": "env_name",
        "query": "${env_name}",
        "skipUrlSync": false,
        "type": "constant"
      }
    ]
  },
  "time": {
    "from": "now-1h",
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
  "title": "AWS RDS",
  "uid": "AWSRDSdbi",
  "version": 2,
  "weekStart": ""
}
