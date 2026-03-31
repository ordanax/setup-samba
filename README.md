# Samba Setup Script для Arch Linux

Автоматический скрипт настройки Samba для создания сетевой шары между Linux и Windows ПК.

## Что делает скрипт

- Устанавливает и настраивает Samba
- Создаёт защищённую шару с паролем (без гостевого доступа)
- Настраивает firewall (UFW) для локальной сети
- Создаёт папку `/home/username/Public` для обмена файлами
- Создаёт Samba-пользователя
- Запускает и включает службы smb и nmb
- Показывает IP и имя ПК для подключения
- Опционально создаёт ярлык на рабочем столе

## Требования

- Arch Linux (или производные: Manjaro, EndeavourOS)
- Права sudo
- Интернет для установки пакетов

## Установка

1. Скачайте скрипт:
```bash
curl -O https://github.com/ordanax/setup-samba/blob/main/setup-samba.sh
chmod +x setup-samba.sh
```

2. Запустите:
```bash
./setup-samba.sh
```

3. Следуйте инструкциям:
   - Введите имя пользователя для шары
   - Введите пароль для доступа к шаре
   - Скопируйте IP или имя ПК для подключения с других устройств

## Подключение к шаре

### С другого Linux ПК:

**Через файловый менеджер:**
```
smb://IP_АДРЕС/Public
# или по имени ПК:
smb://ARCHLINUX/Public
```

**Через терминал:**
```bash
smbclient //192.168.0.100/Public -U username
```

### С Windows:
```
\\192.168.0.100\Public
# или
\\ARCHLINUX\Public
```

### С Android:
Используйте приложения: "Solid Explorer", "CX File Explorer" или "VLC" (для потокового видео)

## Почему имя ПК вместо IP

IP адрес может меняться при перезагрузке (если DHCP). Имя ПК работает через NetBIOS (nmb) и остаётся постоянным:

```bash
# Узнать имя текущего ПК
uname -n

# Проверить NetBIOS имена в сети
nmblookup -S WORKGROUP
```

## Управление Samba

```bash
# Перезапуск
sudo systemctl restart smb nmb

# Проверка статуса
sudo systemctl status smb nmb

# Просмотр текущих подключений
smbstatus

# Изменить пароль пользователя
sudo smbpasswd username

# Добавить нового пользователя
sudo smbpasswd -a newuser
```

## Конфигурация

Конфигурационный файл: `/etc/samba/smb.conf`

Основные параметры шары `[Public]`:
- `path` — путь к папке
- `valid users` — кто имеет доступ
- `writable = Yes` — разрешена запись
- `guest ok = No` — гостевой доступ запрещён

## Безопасность

- Гостевой доступ отключён (требуется пароль)
- Доступ только для указанного пользователя
- Firewall открыт только для локальной сети
- Пароль хранится в зашифрованном виде (Samba database)

## Устранение неполадок

### Не подключается по имени ПК
Проверьте работу nmb:
```bash
sudo systemctl status nmb
```

### Не видно шару в сети
Проверьте firewall:
```bash
sudo ufw status
```

### Ошибка "В соединении отказано"
Проверьте что Samba слушает на всех интерфейсах:
```bash
sudo ss -tlnp | grep smbd
```

Перезапустите Samba:
```bash
sudo systemctl restart smb nmb
```

## Лицензия

MIT License — свободное использование, модификация и распространение.

## О проекте

Скрипт создан для упрощения настройки сетевого обмена файлами в домашних сетях.

**Ссылки:**
- Сайт: https://ordanax.github.io/
- Telegram: https://t.me/linux4at
- MAX: https://max.ru/join/b4GtiNvbjYqeboq-nddswKQJ-cvWiJGoaZdIoV1EUMk
