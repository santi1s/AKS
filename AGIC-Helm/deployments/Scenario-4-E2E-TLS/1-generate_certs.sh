#!/bin/bash
cd ../../certs
#gererate frontend cert
openssl ecparam -out frontend.key -name prime256v1 -genkey
openssl req -new -sha256 -key frontend.key -out frontend.csr -subj "/CN=frontend"
openssl x509 -req -sha256 -days 365 -in frontend.csr -signkey frontend.key -out frontend.crt

#generate backend cert
openssl ecparam -out backend.key -name prime256v1 -genkey
openssl req -new -sha256 -key backend.key -out backend.csr -subj "/CN=backend"
openssl x509 -req -sha256 -days 365 -in backend.csr -signkey backend.key -out backend.crt

cd -
