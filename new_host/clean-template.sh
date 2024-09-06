# https://raw.githubusercontent.com/andrradar/bash-scripts/main/new_host/clean-template.sh
#!/bin/bash

# Удаляем machine-id и создаем новый при следующем запуске
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup

# Удаляем старые DHCP lease
sudo rm -f /var/lib/dhcp/dhclient.*.leases

# Удаляем правила udev для сетевых интерфейсов
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# Удаляем machine-id для D-Bus и создаем символическую ссылку на новый machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Рекомендуется перезагрузить систему после выполнения
echo "Система очищена. Перезагрузите машину для завершения."
