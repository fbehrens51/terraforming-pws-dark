package main

import (
	"bytes"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"time"
)

type Input struct {
	Hosts string `json:"hosts"`
}

type Output struct {
	Certs string `json:"certs"`
}

func main() {
	var input Input
	err := json.NewDecoder(os.Stdin).Decode(&input)
	if err != nil {
		fatal(err)
	}

	output := process(input)
	err = json.NewEncoder(os.Stdout).Encode(output)
	if err != nil {
		fatal(err)
	}
}

func process(input Input) Output {

	hosts := strings.Split(input.Hosts, ",")

	var allRoots = []*x509.Certificate{}
	for _, host := range hosts {
		log.Printf("Finding roots for %s...", host)
		roots, err := findRootsForHost(host)
		if err != nil {
			fatal(err)
		}
		log.Println(fmt.Sprintf("%d roots found for %s", len(roots), host))

		allRoots = append(allRoots, roots...)
	}

	allRoots = uniqueCerts(allRoots)
	log.Println()
	info(fmt.Sprintf("Found %d unique certs across %d hosts:", len(allRoots), len(hosts)))
	for _, cert := range allRoots {
		info(cert.Subject.String())
	}

	log.Println()

	var pool = x509.NewCertPool()
	for _, cert := range allRoots {
		pool.AddCert(cert)
	}

	for _, host := range hosts {
		log.Printf("Validating %s...", host)
		err := validateCertPool(pool, host)
		if err != nil {
			fatal(err)
		} else {
			info("OK")
		}
	}

	buf := new(bytes.Buffer)

	log.Printf("Encoding certs...")
	for _, cert := range allRoots {
		err := pem.Encode(buf, &pem.Block{Type: "CERTIFICATE", Bytes: cert.Raw})
		if err != nil {
			fatal(err)
		}
	}
	info("OK")

	return Output{Certs: buf.String()}
}

var (
	clear = "\u001b[0m"
	red   = "\u001b[31m"
	green = "\u001b[32m"
	cyan  = "\u001b[36m"
)

func color(color, input string) string {
	return color + input + clear
}

func info(info string) {
	log.Println(color(green, info))
}

func fatal(err error) {
	log.Println(color(red, err.Error()))
	os.Exit(1)
}

func uniqueCerts(pool []*x509.Certificate) []*x509.Certificate {
	var uniquePool []*x509.Certificate

	for _, cert := range pool {
		if !contains(uniquePool, cert) {
			uniquePool = append(uniquePool, cert)
		}
	}

	return uniquePool
}

func validateCertPool(pool *x509.CertPool, host string) error {
	dialer := &net.Dialer{Timeout: time.Second * 5}
	conf := &tls.Config{RootCAs: pool}

	conn, err := tls.DialWithDialer(dialer, "tcp", host, conf)
	if err != nil {
		return err
	}
	defer conn.Close()
	return nil
}

func findRootsForHost(host string) ([]*x509.Certificate, error) {
	pool, err := x509.SystemCertPool()
	if err != nil {
		return nil, fmt.Errorf("Error loading system cert pool: %w", err)
	}
	dialer := &net.Dialer{Timeout: time.Second * 5}
	conf := &tls.Config{RootCAs: pool}

	conn, err := tls.DialWithDialer(dialer, "tcp", host, conf)
	if err != nil {
		return nil, fmt.Errorf("Error dialing %s: %w", host, err)
	}
	defer conn.Close()
	state := conn.ConnectionState()
	log.Println("Peer certificates:")
	for _, cert := range state.PeerCertificates {
		log.Println(color(cyan, cert.Subject.String()))
	}

	log.Println()

	var roots []*x509.Certificate

	log.Println("Verified chains:")
	for _, chain := range state.VerifiedChains {
		for _, cert := range chain {
			if contains(state.PeerCertificates, cert) {
				log.Println("Peer", color(cyan, cert.Subject.String()))
			} else {
				log.Println("Root", color(green, cert.Subject.String()))
				roots = append(roots, cert)
			}
		}
		log.Println()
	}

	return roots, nil
}

func contains(pool []*x509.Certificate, cert *x509.Certificate) bool {
	for i := range pool {
		if pool[i].Equal(cert) {
			return true
		}
	}
	return false
}
