#!/bin/bash

# Удаляем machine-id, очищаем DHCP lease и сетевые правила, очищаем историю и логи
sudo truncate -s 0 /etc/machine-id && sudo rm -f /var/lib/dbus/machine-id && sudo ln -s /etc/machine-id /var/lib/dbus/machine-id && \
sudo rm -f /var/lib/dhcp/dhclient.*.leases && sudo rm -f /etc/udev/rules.d/70-persistent-net.rules && \
sudo truncate -s 0 /root/.bash_history && sudo find /var/log -type f -exec truncate -s 0 {} \;

# Создаем скрипт первого запуска и его systemd службу
sudo tee /usr/local/bin/firstboot-setup.sh > /dev/null << 'EOF'
#!/bin/bash
if [ -f /etc/setup_completed ]; then exit 0; fi
truncate -s 0 /etc/machine-id && rm /var/lib/dbus/machine-id && ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF2
network:
  version: 2
  renderer: networkd
  ethernets:
    default:
      match:
        name: e*
      dhcp4: yes
      dhcp-identifier: mac
EOF2
sudo netplan apply && sudo rm -f /var/lib/dhcp/dhclient.*.leases
if [ -f /etc/systemd/network/default.network ]; then sudo sed -i '/\[Network\]/a ClientIdentifier=mac' /etc/systemd/network/default.network
else
sudo mkdir -p /etc/systemd/network && sudo tee /etc/systemd/network/default.network > /dev/null <<EOF3
[Match]
Name=e*
[Network]
DHCP=ipv4
ClientIdentifier=mac
EOF3
fi
sudo systemctl restart systemd-networkd && touch /etc/setup_completed
EOF

# Делаем его исполняемым
sudo chmod +x /usr/local/bin/firstboot-setup.sh

# Создаем и активируем systemd службу
sudo tee /etc/systemd/system/firstboot-setup.service > /dev/null << 'EOF'
[Unit]
Description=First boot setup
[Service]
ExecStart=/usr/local/bin/firstboot-setup.sh
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable firstboot-setup.service

echo "Эталонная ВМ готова для клонирования."
