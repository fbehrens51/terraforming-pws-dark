# Running locally

The go code is invoked by terraform, so it expect json input / output.

```
$ echo '{"hosts":"s3.us-east-2.amazonaws.com:443,hooks.slack.com:443"}' | go run . | jq -r .certs
2021/04/16 12:33:38 Finding roots for s3.us-east-2.amazonaws.com:443...
2021/04/16 12:33:38 Peer certificates:
2021/04/16 12:33:38 CN=*.s3.us-east-2.amazonaws.com,O=Amazon.com\, Inc.,L=Seattle,ST=Washington,C=US
2021/04/16 12:33:38 CN=DigiCert Baltimore CA-2 G2,OU=www.digicert.com,O=DigiCert Inc,C=US
2021/04/16 12:33:38
2021/04/16 12:33:38 Verified chains:
2021/04/16 12:33:38 Peer CN=*.s3.us-east-2.amazonaws.com,O=Amazon.com\, Inc.,L=Seattle,ST=Washington,C=US
2021/04/16 12:33:38 Peer CN=DigiCert Baltimore CA-2 G2,OU=www.digicert.com,O=DigiCert Inc,C=US
2021/04/16 12:33:38 Root CN=Baltimore CyberTrust Root,OU=CyberTrust,O=Baltimore,C=IE
2021/04/16 12:33:38
2021/04/16 12:33:38 1 roots found for s3.us-east-2.amazonaws.com:443
2021/04/16 12:33:38 Finding roots for hooks.slack.com:443...
2021/04/16 12:33:39 Peer certificates:
2021/04/16 12:33:39 CN=slack.com,O=Slack Technologies\, Inc.,L=San Francisco,ST=California,C=US
2021/04/16 12:33:39 CN=DigiCert TLS RSA SHA256 2020 CA1,O=DigiCert Inc,C=US
2021/04/16 12:33:39
2021/04/16 12:33:39 Verified chains:
2021/04/16 12:33:39 Peer CN=slack.com,O=Slack Technologies\, Inc.,L=San Francisco,ST=California,C=US
2021/04/16 12:33:39 Peer CN=DigiCert TLS RSA SHA256 2020 CA1,O=DigiCert Inc,C=US
2021/04/16 12:33:39 Root CN=DigiCert Global Root CA,OU=www.digicert.com,O=DigiCert Inc,C=US
2021/04/16 12:33:39
2021/04/16 12:33:39 1 roots found for hooks.slack.com:443
2021/04/16 12:33:39
2021/04/16 12:33:39 Found 2 unique certs across 2 hosts:
2021/04/16 12:33:39 CN=Baltimore CyberTrust Root,OU=CyberTrust,O=Baltimore,C=IE
2021/04/16 12:33:39 CN=DigiCert Global Root CA,OU=www.digicert.com,O=DigiCert Inc,C=US
2021/04/16 12:33:39
2021/04/16 12:33:39 Validating s3.us-east-2.amazonaws.com:443...
2021/04/16 12:33:39 OK
2021/04/16 12:33:39 Validating hooks.slack.com:443...
2021/04/16 12:33:39 OK
2021/04/16 12:33:39 Encoding certs...
2021/04/16 12:33:39 OK
-----BEGIN CERTIFICATE-----
MIIDdzCCAl+gAwIBAgIEAgAAuTANBgkqhkiG9w0BAQUFADBaMQswCQYDVQQGEwJJ
RTESMBAGA1UEChMJQmFsdGltb3JlMRMwEQYDVQQLEwpDeWJlclRydXN0MSIwIAYD
VQQDExlCYWx0aW1vcmUgQ3liZXJUcnVzdCBSb290MB4XDTAwMDUxMjE4NDYwMFoX
DTI1MDUxMjIzNTkwMFowWjELMAkGA1UEBhMCSUUxEjAQBgNVBAoTCUJhbHRpbW9y
ZTETMBEGA1UECxMKQ3liZXJUcnVzdDEiMCAGA1UEAxMZQmFsdGltb3JlIEN5YmVy
VHJ1c3QgUm9vdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKMEuyKr
mD1X6CZymrV51Cni4eiVgLGw41uOKymaZN+hXe2wCQVt2yguzmKiYv60iNoS6zjr
IZ3AQSsBUnuId9Mcj8e6uYi1agnnc+gRQKfRzMpijS3ljwumUNKoUMMo6vWrJYeK
mpYcqWe4PwzV9/lSEy/CG9VwcPCPwBLKBsua4dnKM3p31vjsufFoREJIE9LAwqSu
XmD+tqYF/LTdB1kC1FkYmGP1pWPgkAx9XbIGevOF6uvUA65ehD5f/xXtabz5OTZy
dc93Uk3zyZAsuT3lySNTPx8kmCFcB5kpvcY67Oduhjprl3RjM71oGDHweI12v/ye
jl0qhqdNkNwnGjkCAwEAAaNFMEMwHQYDVR0OBBYEFOWdWTCCR1jMrPoIVDaGezq1
BE3wMBIGA1UdEwEB/wQIMAYBAf8CAQMwDgYDVR0PAQH/BAQDAgEGMA0GCSqGSIb3
DQEBBQUAA4IBAQCFDF2O5G9RaEIFoN27TyclhAO992T9Ldcw46QQF+vaKSm2eT92
9hkTI7gQCvlYpNRhcL0EYWoSihfVCr3FvDB81ukMJY2GQE/szKN+OMY3EU/t3Wgx
jkzSswF07r51XgdIGn9w/xZchMB5hbgF/X++ZRGjD8ACtPhSNzkE1akxehi/oCr0
Epn3o0WC4zxe9Z2etciefC7IpJ5OCBRLbf1wbWsaY71k5h+3zvDyny67G7fyUIhz
ksLi4xaNmjICq44Y3ekQEe5+NauQrz4wlHrQMz2nZQ/1/I6eYs9HRCwBXbsdtTLS
R9I4LtD+gdwyah617jzV/OeBHRnDJELqYzmp
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----
```

Was using the followin to run, capture output, write to file and then dump subject read in from file:
```shell
go run main.go <<< $(echo "{\"hosts\":\"ec2.us-east-2.amazonaws.com:443,elasticloadbalancing.us-east-2.amazonaws.com:443,s3.us-east-2.amazonaws.com:443,hooks.slack.com:443,pws-dark-artifact-repo.s3.amazonaws.com:443\"}") | jq -r .certs > CHAINED.pem ; openssl crl2pkcs7 -nocrl -certfile CHAINED.pem | openssl pkcs7 -print_certs -text -noout|grep 'Subject:'
```