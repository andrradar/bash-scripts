#!/bin/bash

# Удаляем machine-id и создаем новый при следующем запуске
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup

# Удаляем старые DHCP lease
sudo rm -f /var/lib/dhcp/dhclient.*.leases

# Удаляем правила udev для сетевых интерфейсов
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# Удаляем конфигурацию Netplan (если используется)
sudo rm -f /etc/netplan/*.yaml

# Создаем новый Netplan-файл (если требуется)
sudo tee /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
EOF

# Удаляем machine-id для D-Bus и создаем символическую ссылку на новый machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Очистка истории bash (ввода команд в терминал)
sudo rm -f ~/.bash_history
history -c

# Очистка кэша apt
sudo apt clean

# Очистка временных файлов
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Очистка логов системы
sudo find /var/log -type f -exec truncate -s 0 {} \;

# Очистка мусорных файлов пользователей (если применимо)
sudo rm -rf /home/*/.cache/*
sudo rm -rf /root/.cache/*

# Даем системе немного времени для завершения работы команд
sleep 5

# Корректно выключаем систему через shutdown
echo "Очистка завершена. Корректное выключение машины..."
sudo shutdown now
