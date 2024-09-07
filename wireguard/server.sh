#!/bin/bash
# Настройка ВПС:

apt update && apt upgrade -y
apt install wireguard-tools
mkdir wg
cd wg
cat > wggen.sh << EOF
#!/bin/bash

set -e

if [ -z \$ip_prefix          ]; then ip_prefix=10.0.0; fi
if [ -z \$ip_mask            ]; then ip_mask=24; fi
if [ -z \$start_ip           ]; then start_ip=101; fi
if [ -z \$wg_port            ]; then wg_port=51820; fi
if [ -z \$server_file        ]; then server_file=wg0.conf; fi
if [ -z \$client_file_prefix ]; then client_file_prefix=client; fi
# Изменено поле allowedips для добавления исключения подсети 10.10.4.0/24
if [ -z \$allowedips         ]; then allowedips="0.0.0.0/0, 10.10.4.0/24"; fi
if [ -z "\$DNS"              ]; then DNS='DNS = 1.1.1.1,8.8.8.8'; elif [ "\$DNS" != " " ]; then DNS="DNS = \$DNS"; fi;

postup_rules=postup.rules
postdown_rules=postdown.rules
client_file_suffix=.conf

wg_pub_ip=\`curl -s -4 ifconfig.me\`
number_clients="\$1"


if [ ! "\$number_clients" ]; then
	echo "Usage: \$0 <number of client config files>"
	exit 1
fi

##########################
# Generate server config #
##########################

server_priv_key=\`wg genkey\`
server_pub_key=\`wg pubkey <<< \$server_priv_key\`

echo "[Interface]" > \$server_file
echo "Address = \$ip_prefix.1/\$ip_mask" >> \$server_file
echo "ListenPort = \$wg_port" >> \$server_file
echo "PrivateKey = \$server_priv_key" >> \$server_file

if [ -f ./\$postup_rules ]; then
	while read line; do
		echo "PostUp = \$line" >> \$server_file
	done < \$postup_rules
fi
if [ -f ./\$postdown_rules ]; then
	while read line; do
		echo "PostDown = \$line" >> \$server_file
	done < \$postdown_rules
fi
echo >> \$server_file


###########################
# Generate client configs #
###########################

for ((i=1; i<=\$number_clients; i++)); do

	client_priv_key=\`wg genkey\`
	client_pub_key=\`wg pubkey <<< \$client_priv_key\`

	echo "[Interface]" > \$client_file_prefix\$i\$client_file_suffix
	echo "PrivateKey = \$client_priv_key" >> \$client_file_prefix\$i\$client_file_suffix
	echo "Address = \$ip_prefix.\$((start_ip+i-1))/\$ip_mask" >> \$client_file_prefix\$i\$client_file_suffix
	echo "\$DNS" >> \$client_file_prefix\$i\$client_file_suffix
	echo >> \$client_file_prefix\$i\$client_file_suffix
	echo "[Peer]" >> \$client_file_prefix\$i\$client_file_suffix
	# Изменено поле AllowedIPs
	echo "AllowedIPs = \$allowedips" >> \$client_file_prefix\$i\$client_file_suffix
	echo "PublicKey = \$server_pub_key" >> \$client_file_prefix\$i\$client_file_suffix
	echo "Endpoint = \$wg_pub_ip:\$wg_port" >> \$client_file_prefix\$i\$client_file_suffix
	echo "PersistentKeepalive = 25" >> \$client_file_prefix\$i\$client_file_suffix
	
	# add client to server config file
	echo >> \$server_file
	echo "[Peer]" >> \$server_file
	echo "PublicKey = \$client_pub_key" >> \$server_file
	echo "AllowedIPs = \$ip_prefix.\$((start_ip+i-1))/32" >> \$server_file
 
# Переименовываем клиентский конфиг, используя только IP сервера
mv "\$client_file_prefix\$i\$client_file_suffix" "\$server_ip\$client_file_suffix"

done
exit 0
EOF

# Даём права на исполнение скрипта и запускаем его
chmod +x wggen.sh
./wggen.sh 1    # где 1 - число клиентских конфигов.
cat $server_ip.conf  # Переименованный клиентский конфиг.
mv wg0.conf /etc/wireguard/wg0.conf
systemctl start wg-quick@wg0.service
systemctl enable wg-quick@wg0.service
	@@ -125,6 +113,3 @@ systemctl enable nftables.service
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh
done
exit 0
EOF
chmod +x wggen.sh
./wggen.sh 1    # где 1 - число клиентских конфигов.
cat client1.conf  # Это клиентский конфиг. Его надо перенести на ВМ.
mv wg0.conf /etc/wireguard/wg0.conf
systemctl start wg-quick@wg0.service
systemctl enable wg-quick@wg0.service

# Настройка файрвола и форвардинга
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/net.ipv4.ip_forward=1/s/#//' /etc/sysctl.conf

nft add table ip wg
nft add chain ip wg prerouting {type nat hook prerouting priority dstnat\; policy accept\;}
nft add rule ip wg prerouting iif "ens3" tcp dport != 22 counter dnat to 10.0.0.101
nft add rule ip wg prerouting iif "ens3" udp dport != 51820 counter dnat to 10.0.0.101
nft add chain ip wg postrouting {type nat hook postrouting priority srcnat\; policy accept\; }
nft add rule ip wg postrouting iif wg0 oif ens3 counter masquerade

nft -s list ruleset >> /etc/nftables.conf
systemctl start nftables.service
systemctl enable nftables.service

# Отключение авторизации по паролю для SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh
