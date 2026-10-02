#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE="zerro:local"
BIN_DIR="$HOME/bin"
BIN_SCRIPT="$BIN_DIR/zerro-launcher.sh"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/zerro-192px.png"

echo "📦 Zerro Installer"
echo "📁 Project: $PROJECT_DIR"

# --- 1. Определяем контейнерный движок ---
if command -v podman > /dev/null 2>&1; then
    CONTAINER_CMD="podman"
elif command -v docker > /dev/null 2>&1; then
    CONTAINER_CMD="docker"
else
    echo "❌ Не найден ни podman, ни docker. Установите один из них."
    exit 1
fi
echo "🐳 Движок: $CONTAINER_CMD"

# --- 2. Собираем образ (если нет или передан --rebuild) ---
if [ "$1" = "--rebuild" ] || ! $CONTAINER_CMD image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "🔨 Собираем образ $IMAGE..."
    $CONTAINER_CMD build -t "$IMAGE" -f "$PROJECT_DIR/local.dockerfile" "$PROJECT_DIR"
    echo "✅ Образ собран"
else
    echo "✅ Образ $IMAGE уже существует (--rebuild для пересборки)"
fi

# --- 3. Копируем launcher ---
mkdir -p "$BIN_DIR"
install -m 0755 "$SCRIPT_DIR/zerro-launcher.sh" "$BIN_SCRIPT"
echo "📄 Launcher установлен в $BIN_SCRIPT"

# --- 4. Иконка ---
mkdir -p "$ICON_DIR"
cp "$PROJECT_DIR/public/icons/192px.png" "$ICON_PATH"
echo "🖼️  Иконка скопирована в $ICON_PATH"

# --- 5. Ярлык на рабочем столе ---
DESKTOP_DIR="$HOME/Desktop"
[ -d "$HOME/Рабочий стол" ] && DESKTOP_DIR="$HOME/Рабочий стол"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/Zerro.desktop" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Zerro
Comment=Unofficial ZenMoney client
Exec=$BIN_SCRIPT
Icon=$ICON_PATH
Terminal=false
Categories=Finance;
StartupNotify=true
DESKTOP

chmod +x "$DESKTOP_DIR/Zerro.desktop"
echo "🖥️  Ярлык: $DESKTOP_DIR/Zerro.desktop"

echo ""
echo "🎉 Готово!"
echo "👉 Запуск через ярлык или: $BIN_SCRIPT"

