#!/bin/bash
# Получение root-доступа
sudo -s

# Установка пароля для root (ожидание ввода от пользователя)
echo "Введите новый пароль для root:"
sudo passwd root

# Разрешение логина по SSH для root и перезагрузка SSH
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo service ssh restart

# Отключение cloud-init
sudo touch /etc/cloud/cloud-init.disabled

# Обновление системы и очистка (с автоматическим подтверждением)
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Установка необходимых пакетов (с автоматическим подтверждением)
sudo apt install -y curl nano jq ccze

# Настройка iptables для локальных соединений
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Настройка часового пояса
sudo timedatectl set-timezone Europe/Moscow

# Отключение авторизации по паролю для всех пользователей
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo service ssh restart

# Перезагрузка системы для применения изменений
sudo reboot
