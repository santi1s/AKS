#!/bin/bash
echo -e "\nSHA1 Fingerprint from cert used to create TLS CM"
openssl x509 -in certs/server.crt -noout -fingerprint
echo -e "\nSHA1 Fingerprint from cert returned by AppGW"
openssl x509 -in <(openssl s_client -connect 52.228.26.165:443 -prexit 2>/dev/null) -noout -fingerprint

