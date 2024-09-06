#!/bin/bash

# Остановить скрипт при ошибке
set -e

LOGFILE="/var/log/script_setup.log"

# Функция для логирования
log() {
    echo "$(date +"%Y-%m-%d %T") - $1" | tee -a $LOGFILE
}

# Проверка root-доступа
if [[ $EUID -ne 0 ]]; then
   log "Этот скрипт должен быть запущен с правами root"
   exit 1
fi

log "Скрипт запущен с правами root."

# Проверка и настройка SSH для root
SSH_CONFIG="/etc/ssh/sshd_config"
if grep -q "^PermitRootLogin" $SSH_CONFIG; then
    log "Настройка PermitRootLogin уже существует. Обновляем..."
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' $SSH_CONFIG
else
    log "Добавляем PermitRootLogin в конфигурацию SSH."
    echo "PermitRootLogin yes" >> $SSH_CONFIG
fi

# Перезапуск SSH
log "Перезапуск службы SSH."
service ssh restart

# Отключение cloud-init
log "Отключение cloud-init."
touch /etc/cloud/cloud-init.disabled

# Обновление системы
log "Обновление системы и установка пакетов."
apt update && apt upgrade -y && apt autoremove -y

# Установка полезных пакетов
log "Установка curl, nano, jq, ccze."
apt install -y curl nano jq ccze

# Настройка iptables
log "Настройка iptables для локальных соединений."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Настройка часового пояса
log "Настройка часового пояса на Europe/Moscow."
timedatectl set-timezone Europe/Moscow

# Отключение авторизации по паролю для всех пользователей (кроме root)
if grep -q "^PasswordAuthentication" $SSH_CONFIG; then
    log "Обновляем настройку PasswordAuthentication."
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG
else
    log "Добавляем PasswordAuthentication в конфигурацию SSH."
    echo "PasswordAuthentication no" >> $SSH_CONFIG
fi

# Перезапуск SSH после изменения конфигурации
log "Перезапуск SSH после изменения конфигурации."
service ssh restart

# Перезагрузка системы
log "Перезагрузка системы."
reboot
