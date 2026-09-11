#!/bin/bash
# restrict-access.sh — deploy to /usr/local/bin/restrict-access.sh on the NPM LXC
set -e

#! Don't forget to chmod 600 + chown root:root the file
# mkdir the directory first + nano the file
source /etc/proxmox/container_ip.conf

# Port 81 (admin UI): PC + admin VPN peer only
iptables -C INPUT -p tcp --dport 81 -s "$PC_IP" -j ACCEPT 2>/dev/null || \
  iptables -A INPUT -p tcp --dport 81 -s "$PC_IP" -j ACCEPT
iptables -C INPUT -p tcp --dport 81 -s "$ADMIN_VPN_IP" -j ACCEPT 2>/dev/null || \
  iptables -A INPUT -p tcp --dport 81 -s "$ADMIN_VPN_IP" -j ACCEPT
iptables -C INPUT -p tcp --dport 81 -j DROP 2>/dev/null || \
  iptables -A INPUT -p tcp --dport 81 -j DROP

# Ports 80/443 (proxied traffic): WireGuard peer subnet + LAN.
# Per-service locking (e.g. the Pterodactyl Panel) happens in NPM's own
# Access Lists per proxy host — see step 7 — not here.
for PORT in 80 443; do
  iptables -C INPUT -p tcp --dport "$PORT" -s "$LAN_SUBNET" -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport "$PORT" -s "$LAN_SUBNET" -j ACCEPT
  iptables -C INPUT -p tcp --dport "$PORT" -s "$WG_SUBNET" -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport "$PORT" -s "$WG_SUBNET" -j ACCEPT
  iptables -C INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null || \
    iptables -A INPUT -p tcp --dport "$PORT" -j DROP
done