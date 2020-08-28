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


echo "" > final-ca-cert.pem

for host_port in "${trusted_hosts[@]}"; do
    find_trusted_cert $host_port >> final-ca-cert.pem
done

for host_port in "${trusted_hosts[@]}"; do
    openssl s_client -CApath ./empty-dir -CAfile final-ca-cert.pem -connect $host_port < /dev/null > /dev/null 2>/dev/null
done

single_line_cert_pem=$(awk '{printf "%s\\n", $0}' final-ca-cert.pem)
echo "{\"certs\":\"${single_line_cert_pem}\"}"

rm -rf tmp-files empty-dir final-ca-cert.pem
