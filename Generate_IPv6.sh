#!/bin/bash

# === CONFIG ===
SUBNET_PREFIX="2a01:4ff:1f0:3e5b"
INTERFACE="eth0"

# === Generate valid IPv6 ===
RANDOM_IPV6_SUFFIX() {
  printf "%x:%x:%x:%x" \
    $((RANDOM & 0xFFFF)) \
    $((RANDOM & 0xFFFF)) \
    $((RANDOM & 0xFFFF)) \
    $((RANDOM & 0xFFFF))
}

SUFFIX=$(RANDOM_IPV6_SUFFIX)
FULL_IPV6="${SUBNET_PREFIX}:${SUFFIX}"

# === Assign it ===
echo "[+] Assigning ${FULL_IPV6}/64 to ${INTERFACE}..."
ip -6 addr add ${FULL_IPV6}/64 dev ${INTERFACE}

# === Test ===
echo "[+] Test with:"
echo "    curl -g -6 http://[${FULL_IPV6}]"
