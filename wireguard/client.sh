# https://raw.githubusercontent.com/andrradar/bash-scripts/main/wireguard/client.sh
#!/bin/bash
### Настройка ВМ

sudo apt update
sudo apt install wireguard-tools
# Клиентский конфиг client1.conf с сервера надо сохранить на ВМ под именем wg0.conf в текущей дириктории
sudo mv wg0.conf /etc/wireguard/

# Меням порт ssh на 62222?
# sudo sed -i 's/#Port 22/Port 62222/' /etc/ssh/sshd_config

# Запускаем WG
sudo systemctl daemon-reload
sudo systemctl restart ssh.service
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service
