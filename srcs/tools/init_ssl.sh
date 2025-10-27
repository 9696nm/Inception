#!/bin/sh

CERT_DIR="./certs"

if [ ! -d "$CERT_DIR" ]; then
  mkdir -p "$CERT_DIR"
fi

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$CERT_DIR/inception.key" -out "$CERT_DIR/inception.crt" -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=Inception/OU=IT/CN=inception.com"
