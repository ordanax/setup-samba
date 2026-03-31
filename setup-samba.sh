#!/bin/bash

echo "=== Скрипт настройки Samba ==="
echo ""

# Ask for username
read -p "Введите имя пользователя для шары: " SMB_USER

if [ -z "$SMB_USER" ]; then
    echo "Ошибка: имя пользователя не может быть пустым"
    exit 1
fi

# Detect home directory
if [ "$SMB_USER" = "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$SMB_USER"
fi

echo ""
echo "Установка Samba..."
sudo pacman -S samba gvfs gvfs-smb --noconfirm

# Create config
cat > /tmp/smb.conf << EOF
[global]
   workgroup = WORKGROUP
   server string = Samba
   security = user
   create mask = 0664
   directory mask = 0775
   hide dot files = yes

[Public]
   comment = Общая папка
   path = /home/ordanax/Public
   browseable = Yes
   writable = Yes
   read only = no
   guest ok = No
   valid users = $SMB_USER
   create mask = 0666
   directory mask = 0775
EOF

sudo cp /tmp/smb.conf /etc/samba/smb.conf

# Configure firewall
echo ""
echo "Настройка firewall..."
MY_IP=$(ip addr show | grep "inet 192.168\|inet 10.\|inet 172." | head -1 | awk '{print $2}' | cut -d'/' -f1)
if [ -n "$MY_IP" ]; then
    NETWORK=$(echo $MY_IP | sed 's/\.[0-9]*$/.0\/24/')
    echo "  Обнаружена сеть: $NETWORK"
    sudo ufw allow from $NETWORK
else
    echo "  Внимание: не удалось определить сеть, пропускаем настройку UFW"
fi

# Create directories
echo ""
echo "Создание директорий..."
if [ -d "/home/ordanax/Public" ]; then
    echo "  /home/ordanax/Public уже существует"
else
    echo "  Создаём /home/ordanax/Public..."
    sudo mkdir -p "/home/ordanax/Public"
fi
sudo chown "$SMB_USER:$SMB_USER" "/home/ordanax/Public"
sudo chmod 755 "/home/ordanax/Public"

# Create Samba user
echo ""
echo "Создание пользователя Samba '$SMB_USER'..."
echo "Введите пароль для доступа к шаре (обязательно):"
sudo smbpasswd -a "$SMB_USER"

# Enable and start services
echo ""
echo "Запуск служб Samba..."
sudo systemctl enable smb nmb
sudo systemctl start smb nmb

# Get IP address
echo ""
echo "=== Настройка завершена ==="
MY_IP=$(ip addr show | grep "inet 192.168\|inet 10.\|inet 172." | head -1 | awk '{print $2}' | cut -d'/' -f1)
echo ""
echo ""
echo "=== Подключение ==="
echo "По IP:     smb://$MY_IP/Public"
echo "По имени:  smb://$(uname -n | tr '[:lower:]' '[:upper:]')/Public"
echo "Windows:   \\\\\\\\$(uname -n | tr '[:lower:]' '[:upper:]')\\\\Public"
echo ""
echo "Имя ПК работает даже при смене IP (через NetBIOS/nmb)"
echo "Узнать имя ПК: uname -n"
echo ""
echo "Логин: $SMB_USER"
echo "Пароль: (тот что ввели)"
echo ""
echo "=== Статус служб ==="
sudo systemctl is-active smb nmb && echo "Samba запущена!" || echo "ОШИБКА: Samba не запустилась"

echo ""
read -p "Создать ярлык на рабочем столе? (y/n): " CREATE_SHORTCUT
if [ "$CREATE_SHORTCUT" = "y" ] || [ "$CREATE_SHORTCUT" = "Y" ]; then
    read -p "Введите имя ПК (или нажмите Enter для $(uname -n | tr '[:lower:]' '[:upper:]')): " PC_NAME
    if [ -z "$PC_NAME" ]; then
        PC_NAME=$(uname -n | tr '[:lower:]' '[:upper:]')
    fi
    
    echo ""
    echo "Создание ярлыка..."
    cat > ~/Desktop/Samba-Public.desktop << EOF
[Desktop Entry]
Name=Public Samba
Comment=Samba share on $PC_NAME
Exec=xdg-open smb://$PC_NAME/Public
Type=Application
Terminal=false
Icon=folder-network
EOF
    chmod +x ~/Desktop/Samba-Public.desktop
    echo "Ярлык создан на рабочем столе"
fi
