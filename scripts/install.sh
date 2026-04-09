#!/bin/bash
set -e

# Определяем путь к папке проекта (на один уровень выше scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Zerro Installer"
echo "📁 Project: $PROJECT_DIR"

# 1. Собираем образ, если его нет
if docker image inspect zerro:local > /dev/null 2>&1; then
    echo "✅ Образ zerro:local уже существует"
else
    echo "🔨 Собираем образ zerro:local..."
    docker build -t zerro:local -f "$PROJECT_DIR/local.dockerfile" "$PROJECT_DIR"
    echo "✅ Образ собран"
fi

# 2. Копируем скрипт запуска в ~/bin/
BIN_DIR="$HOME/bin"
BIN_SCRIPT="$BIN_DIR/zerro-launcher.sh"
mkdir -p "$BIN_DIR"

# Копируем скрипт и подставляем правильный путь к проекту
cat > "$BIN_SCRIPT" << SCRIPT
#!/bin/bash
PROJECT_DIR="$PROJECT_DIR"

# Проверяем запущен ли контейнер
if docker ps --format "table {{.Names}}" | grep -q "^zerro-app$"; then
    echo "✅ Zerro уже запущен"
    google-chrome --disable-extensions --app=http://localhost:3000 > /dev/null 2>&1 &
    disown
    exit 0
fi

# Проверяем, есть ли остановленный контейнер
if docker ps -a --format '{{.Names}}' | grep -q "^zerro-app$"; then
    CONTAINER_IMAGE=\$(docker inspect --format='{{.Image}}' zerro-app 2>/dev/null)
    CURRENT_IMAGE=\$(docker inspect --format='{{.Id}}' zerro:local 2>/dev/null)

    if [ "\$CONTAINER_IMAGE" == "\$CURRENT_IMAGE" ]; then
        echo "⚡ Образ не менялся, быстро запускаем контейнер..."
        docker start zerro-app
    else
        echo "🔄 Образ обновился, пересоздаем контейнер..."
        docker rm zerro-app > /dev/null 2>&1
    fi
else
    echo "🚀 Создаем новый контейнер..."
fi

# Если контейнер не запущен — создаем/запускаем
if ! docker ps --format '{{.Names}}' | grep -q "^zerro-app$"; then
    docker run -d \
      --name zerro-app \
      -p 3000:3000 \
      zerro:local
fi

# Ждем готовности
echo "⏳ Ожидаем запуск..."
for i in {1..30}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Zerro запущен!"
        break
    fi
    sleep 1
done

# Открываем браузер
google-chrome \
  --disable-extensions \
  --disable-background-mode \
  --no-first-run \
  --app=http://localhost:3000 > /dev/null 2>&1 &

# Ждем закрытия Chrome
echo "📱 Закройте окно для остановки Zerro..."
while pgrep -f "chrome.*--app=http://localhost:3000" > /dev/null; do
    sleep 2
done

# Останавливаем контейнер
docker stop zerro-app > /dev/null
echo "✅ Готово!"
SCRIPT

chmod +x "$BIN_SCRIPT"
echo "📄 Скрипт установлен в $BIN_SCRIPT"

# 3. Создаём ярлык на рабочем столе
# Определяем рабочий стол (популярные варианты)
DESKTOP_DIR="$HOME/Desktop"
if [ -d "$HOME/Рабочий стол" ]; then
    DESKTOP_DIR="$HOME/Рабочий стол"
fi
mkdir -p "$DESKTOP_DIR"

ICON_PATH="$PROJECT_DIR/public/icons/192px.png"

cat > "$DESKTOP_DIR/Zerro.desktop" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Zerro Launcher
Comment=Запуск Zerro локально через Docker
Exec=$BIN_SCRIPT
Icon=$ICON_PATH
Terminal=false
Categories=Finance;
StartupNotify=true
DESKTOP

chmod +x "$DESKTOP_DIR/Zerro.desktop"
echo "🖥️  Ярлык установлен в $DESKTOP_DIR/Zerro.desktop"

echo ""
echo "🎉 Zerro готов к использованию!"
echo "👉 Запустите через ярлык или: ~/bin/zerro-launcher.sh"
