#!/bin/bash

# Остановить скрипт при ошибке
set -e

# Если нужно получить root-доступ с одного раза
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами root" 
   exit 1
fi

# Установка пароля для root
echo "Введите новый пароль для root:"
passwd root

# Разрешение логина по SSH для root и перезагрузка SSH
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
service ssh restart

# Отключение cloud-init
touch /etc/cloud/cloud-init.disabled

# Обновление системы и очистка
apt update && apt upgrade -y && apt autoremove -y

# Установка необходимых пакетов
apt install -y curl nano jq ccze

# Настройка iptables для локальных соединений
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Настройка часового пояса
timedatectl set-timezone Europe/Moscow

# Отключение авторизации по паролю для всех пользователей
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
service ssh restart

# Перезагрузка системы
reboot
