iptables -F INPUT

# Allow established/related
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Port 81 - PC by both LAN and VPN IP
iptables -A INPUT -s 192.168.0.xxx -p tcp --dport 81 -j ACCEPT # PC LAN IP
iptables -A INPUT -s 192.168.0.xxx -p tcp --dport 81 -j ACCEPT # NPM LAN IP
iptables -A INPUT -s 10.0.0.2 -p tcp --dport 81 -j ACCEPT
iptables -A INPUT -p tcp --dport 81 -j DROP

# Port 80/443 - LAN and WireGuard subnet
iptables -A INPUT -s 192.168.0.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -s 192.168.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j DROP
iptables -A INPUT -p tcp --dport 443 -j DROP

netfilter-persistent save
iptables -L INPUT -n -v --line-numbers
