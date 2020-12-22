#!/usr/bin/env bash

cd $(dirname $0)

mkdir -p ./tmp-files/

function find_trusted_cert() {
    local host_port=$1

    cat /usr/lib/ssl/certs/ca-certificates.crt | awk -v n=1 'split_after == 1 {n++;split_after=0}
                                                            /-----END CERTIFICATE-----/ {split_after=1}
                                                            NF {print > "tmp-files/ca_cert_" n ".pem"}'

    # Get a server's cert:
    local cert_chain=$(echo "" | openssl s_client -connect ${host_port} -showcerts 2>/dev/null |
        sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')

    echo "$cert_chain" | awk -v n=1 'split_after == 1 {n++;split_after=0}
                                    /-----END CERTIFICATE-----/ {split_after=1}
                                    NF {print > "tmp-files/cert_" n ".pem"}'

    local certs=( tmp-files/cert_*.pem )
    local server_cert=("${certs[0]}")
    local intermediate_certs=("${certs[@]:1}")

    local cmd="openssl verify -purpose sslserver"
    for cert in "${intermediate_certs[@]}"; do
        cmd="$cmd -untrusted $cert"
    done

    mkdir -p empty-dir
    found_cert=1

    for ca_cert in tmp-files/ca_cert_*.pem; do
        local verify_cmd="$cmd -CApath ./empty-dir -CAfile $ca_cert $server_cert"
        if $verify_cmd > /dev/null 2>/dev/null; then
            local ca_subject=$(openssl x509 -noout -subject < $ca_cert)
            local server_subject=$(openssl x509 -noout -subject < $server_cert)

            cat $ca_cert
            found_cert=0
        fi
    done

    return $found_cert
}

function parse_hosts() {
    local IFS=','
    trusted_hosts=($(jq -r .hosts))
}

parse_hosts

# hard coded this intermediate cert for s3 in all four US regions.
# Remove after Amazon begins using their own CA's in March of `21.

echo "-----BEGIN CERTIFICATE-----
MIIEYzCCA0ugAwIBAgIQAYL4CY6i5ia5GjsnhB+5rzANBgkqhkiG9w0BAQsFADBa
MQswCQYDVQQGEwJJRTESMBAGA1UEChMJQmFsdGltb3JlMRMwEQYDVQQLEwpDeWJl
clRydXN0MSIwIAYDVQQDExlCYWx0aW1vcmUgQ3liZXJUcnVzdCBSb290MB4XDTE1
MTIwODEyMDUwN1oXDTI1MDUxMDEyMDAwMFowZDELMAkGA1UEBhMCVVMxFTATBgNV
BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEjMCEG
A1UEAxMaRGlnaUNlcnQgQmFsdGltb3JlIENBLTIgRzIwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQC75wD+AAFz75uI8FwIdfBccHMf/7V6H40II/3HwRM/
sSEGvU3M2y24hxkx3tprDcFd0lHVsF5y1PBm1ITykRhBtQkmsgOWBGmVU/oHTz6+
hjpDK7JZtavRuvRZQHJaZ7bN5lX8CSukmLK/zKkf1L+Hj4Il/UWAqeydjPl0kM8c
+GVQr834RavIL42ONh3e6onNslLZ5QnNNnEr2sbQm8b2pFtbObYfAB8ZpPvTvgzm
+4/dDoDmpOdaxMAvcu6R84Nnyc3KzkqwIIH95HKvCRjnT0LsTSdCTQeg3dUNdfc2
YMwmVJihiDfwg/etKVkgz7sl4dWe5vOuwQHrtQaJ4gqPAgMBAAGjggEZMIIBFTAd
BgNVHQ4EFgQUwBKyKHRoRmfpcCV0GgBFWwZ9XEQwHwYDVR0jBBgwFoAU5Z1ZMIJH
WMys+ghUNoZ7OrUETfAwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMC
AYYwNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
Y2VydC5jb20wOgYDVR0fBDMwMTAvoC2gK4YpaHR0cDovL2NybDMuZGlnaWNlcnQu
Y29tL09tbmlyb290MjAyNS5jcmwwPQYDVR0gBDYwNDAyBgRVHSAAMCowKAYIKwYB
BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwDQYJKoZIhvcNAQEL
BQADggEBAC/iN2bDGs+RVe4pFPpQEL6ZjeIo8XQWB2k7RDA99blJ9Wg2/rcwjang
B0lCY0ZStWnGm0nyGg9Xxva3vqt1jQ2iqzPkYoVDVKtjlAyjU6DqHeSmpqyVDmV4
7DOMvpQ+2HCr6sfheM4zlbv7LFjgikCmbUHY2Nmz+S8CxRtwa+I6hXsdGLDRS5rB
bxcQKegOw+FUllSlkZUIII1pLJ4vP1C0LuVXH6+kc9KhJLsNkP5FEx2noSnYZgvD
0WyzT7QrhExHkOyL4kGJE7YHRndC/bseF/r/JUuOUFfrjsxOFT+xJd1BDKCcYm1v
upcHi9nzBhDFKdT3uhaQqNBU4UtJx5g=
-----END CERTIFICATE-----" > final-ca-cert.pem

for host_port in "${trusted_hosts[@]}"; do
    find_trusted_cert $host_port >> final-ca-cert.pem
done

for host_port in "${trusted_hosts[@]}"; do
    openssl s_client -CApath ./empty-dir -CAfile final-ca-cert.pem -connect $host_port < /dev/null > /dev/null 2>/dev/null
done

single_line_cert_pem=$(awk '{printf "%s\\n", $0}' final-ca-cert.pem)
echo "{\"certs\":\"${single_line_cert_pem}\"}"

rm -rf tmp-files empty-dir final-ca-cert.pem
