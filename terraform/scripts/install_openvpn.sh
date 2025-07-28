#!/bin/bash
set -e

# 1. 필수 패키지 설치
yum update -y
yum groupinstall -y "Development Tools"
yum install -y gcc perl wget tar make zlib-devel pam-devel openssl-devel lzo lzo-devel unzip

# 2. OpenSSL 3.2.2 수동 설치
cd /usr/local/src
wget https://www.openssl.org/source/openssl-3.2.2.tar.gz
tar -xvzf openssl-3.2.2.tar.gz
cd openssl-3.2.2
./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
make -j$(nproc)
make install

# 3. 시스템 OpenSSL 경로 재설정
echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl.conf
ldconfig
mv /usr/bin/openssl /usr/bin/openssl.bak
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
echo 'export PATH=/usr/local/openssl/bin:$PATH' >> /etc/profile
echo 'export LD_LIBRARY_PATH=/usr/local/openssl/lib' >> /etc/profile
source /etc/profile

# 4. OpenVPN 설치
cd /usr/local/src
wget https://swupdate.openvpn.org/community/releases/openvpn-2.6.9.tar.gz
tar -xzf openvpn-2.6.9.tar.gz
cd openvpn-2.6.9
./configure
make -j$(nproc)
make install

# 5. EasyRSA 설치
cd /etc/openvpn
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.7/EasyRSA-3.1.7.tgz
tar -xzf EasyRSA-3.1.7.tgz
mv EasyRSA-3.1.7 easy-rsa
cd easy-rsa
./easyrsa init-pki
echo -ne '\n' | ./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1 nopass
openvpn --genkey --secret ta.key

# 6. 서버 설정 파일 생성
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
auth SHA256
tls-auth /etc/openvpn/easy-rsa/ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

# 7. IP 포워딩 활성화
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# 8. 방화벽 규칙 추가
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables

# 9. systemd 서비스 등록
cat > /etc/systemd/system/openvpn.service <<EOF
[Unit]
Description=OpenVPN service
After=network.target

[Service]
ExecStart=/usr/local/sbin/openvpn --config /etc/openvpn/server.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable openvpn
systemctl start openvpn
