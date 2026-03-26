#!/bin/bash
echo "=== ПОЛНОЕ ВОССТАНОВЛЕНИЕ СЕТИ И SSH ==="

# 1. Полный сброс фаервола
echo "[1/6] Сброс iptables..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# 2. Удаляем ufw если есть (Ubuntu/Debian)
echo "[2/6] Отключение ufw..."
ufw disable 2>/dev/null

# 3. Останавливаем firewalld (CentOS/RHEL)
echo "[3/6] Остановка firewalld..."
systemctl stop firewalld 2>/dev/null
systemctl disable firewalld 2>/dev/null

# 4. Перезапускаем сеть
echo "[4/6] Перезапуск сетевых служб..."
systemctl restart networking 2>/dev/null || systemctl restart NetworkManager 2>/dev/null || service networking restart 2>/dev/null

# 5. Настраиваем SSH
echo "[5/6] Настройка SSH..."
# Создаем резервную копию
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null

# Убираем все ограничения
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null
sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
sed -i 's/^DenyUsers.*//' /etc/ssh/sshd_config 2>/dev/null
sed -i 's/^AllowUsers.*//' /etc/ssh/sshd_config 2>/dev/null

# Гарантируем базовые настройки
echo "" >> /etc/ssh/sshd_config
echo "# Восстановление доступа" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "Port 22" >> /etc/ssh/sshd_config

# Перезапускаем SSH
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service sshd restart 2>/dev/null

# 6. Проверяем порт
echo "[6/6] Проверка..."
sleep 2
ss -tlnp | grep :22
ip a | grep inet

echo ""
echo "=== ГОТОВО ==="
echo "Теперь попробуйте подключиться по SSH: ssh root@ВАШ_IP"
echo "Если пароль root не работает, войдите в VNC как обычный пользователь"
echo "и выполните: sudo passwd root"