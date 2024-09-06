#!/bin/bash

# Загружаем и создаем скрипт для настройки на клонах
cat <<'EOF' > /usr/local/bin/firstboot-setup.sh
#!/bin/bash

# Проверяем наличие флага, чтобы не выполнять скрипт повторно
if [ -f /etc/setup_completed ]; then
  echo "Скрипт уже выполнен ранее, пропускаем настройку."
  exit 0
fi

# Удаляем и создаем символическую ссылку для machine-id
echo -n > /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Проверяем и настраиваем dhcp-identifier в netplan
if grep -q 'dhcp-identifier: mac' /etc/netplan/*.yaml; then
  echo "dhcp-identifier уже настроен на MAC."
else
  sudo tee /etc/netplan/01-netcfg.yaml <<EOF2
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
fi

# Применяем настройки Netplan
sudo netplan apply

# Удаляем старые DHCP lease
sudo rm -f /var/lib/dhcp/dhclient.*.leases

# Создаем флаг-файл, чтобы знать, что скрипт уже выполнен
touch /etc/setup_completed

echo "Настройка завершена. Машина готова к работе."
EOF

# Делаем скрипт исполняемым
chmod +x /usr/local/bin/firstboot-setup.sh

# Добавляем скрипт в автозагрузку
if [ ! -f /etc/rc.local ]; then
  sudo touch /etc/rc.local
  sudo chmod +x /etc/rc.local
fi

if ! grep -q '/usr/local/bin/firstboot-setup.sh' /etc/rc.local; then
  echo "/usr/local/bin/firstboot-setup.sh" | sudo tee -a /etc/rc.local
fi

echo "Эталонная ВМ готова для клонирования."
