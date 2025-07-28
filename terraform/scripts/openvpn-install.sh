#!/bin/bash
# 기본적인 OpenVPN 설치 자동화 스크립트
# Amazon Linux 2 기준

yum update -y
yum install -y epel-release
yum install -y openvpn easy-rsa firewalld

systemctl enable firewalld
systemctl start firewalld

EASYRSA_DIR=/etc/openvpn/easy-rsa
mkdir -p $EASYRSA_DIR
cp -r /usr/share/easy-rsa/3/* $EASYRSA_DIR
cd $EASYRSA_DIR

./easyrsa init-pki
echo -ne "\n" | ./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1 nopass
./easyrsa gen-crl

cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn
cp pki/crl.pem /etc/openvpn
chown nobody:nobody /etc/openvpn/crl.pem

cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
crl-verify crl.pem
topology subnet
server 10.8.0.0 255.255.255.0
persist-key
persist-tun
keepalive 10 120
cipher AES-256-CBC
user nobody
group nobody
status openvpn-status.log
verb 3
EOF

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

firewall-cmd --add-service=openvpn --permanent
firewall-cmd --add-port=1194/udp --permanent
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload

systemctl start openvpn@server
systemctl enable openvpn@server