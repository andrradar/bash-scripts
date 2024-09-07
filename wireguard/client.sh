#!/bin/bash
#команды
#sudo systemctl restart wg-quick@wg0
#sudo wg

### Настройка ВМ
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt update
sudo apt install wireguard-tools

# Ищем файл с расширением .conf в домашней директории
conf_file=$(find ~ -maxdepth 1 -name "*.conf" | head -n 1)

if [ -z "$conf_file" ]; then
    echo "Конфигурационный файл .conf не найден в домашней директории."
    exit 1
fi

# Переименовываем найденный файл в wg0.conf и перемещаем его
sudo mv "$conf_file" /etc/wireguard/wg0.conf
echo "Конфигурационный файл $conf_file перемещён в /etc/wireguard/ под именем wg0.conf"

# Меняем порт ssh на 62222 (если необходимо)
# sudo sed -i 's/#Port 22/Port 62222/' /etc/ssh/sshd_config

# Перезапускаем WireGuard
sudo systemctl daemon-reload
sudo systemctl restart ssh.service
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service
