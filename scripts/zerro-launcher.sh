#!/bin/bash
# Zerro launcher (production): запускает контейнер из готового образа
# и открывает окно браузера. Не требует исходников на диске.
# Защищён от двойного запуска через flock.
# Поддерживает podman и docker (автоопределение).

set -e

# --- Определение контейнерного движка ---
if [ -n "$CONTAINER_CMD" ]; then
    :
elif command -v podman > /dev/null 2>&1; then
    CONTAINER_CMD="podman"
elif command -v docker > /dev/null 2>&1; then
    CONTAINER_CMD="docker"
else
    echo "❌ Не найден ни podman, ни docker"
    exit 1
fi

IMAGE="zerro:local"
CONTAINER="zerro-app"
PORT=3000
URL="http://localhost:${PORT}"
BROWSER="${BROWSER:-google-chrome}"
CHROME_PROFILE="${HOME}/.cache/zerro-chrome-profile"
LOCKFILE="/tmp/zerro-launcher.lock"

# --- 1. Защита от параллельного запуска ---
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "⏳ Launcher уже работает, выходим"
    exit 0
fi

# --- 2. Проверяем образ ---
if ! $CONTAINER_CMD image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "❌ Образ $IMAGE не найден."
    echo "   Соберите его: $CONTAINER_CMD build -t $IMAGE -f local.dockerfile ."
    exit 1
fi

# --- 3. Поднимаем контейнер ---
if $CONTAINER_CMD ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    if $CONTAINER_CMD ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        echo "✅ Zerro уже запущен"
    else
        echo "⚡ Поднимаем остановленный контейнер..."
        $CONTAINER_CMD start "$CONTAINER" > /dev/null
    fi
else
    echo "🚀 Создаём новый контейнер..."
    $CONTAINER_CMD run -d \
        --name "$CONTAINER" \
        -p "${PORT}:3000" \
        "$IMAGE"
fi

# --- 4. Ждём готовности ---
echo "⏳ Ожидаем запуск..."
READY=0
for i in {1..30}; do
    if curl -s -o /dev/null "$URL"; then
        READY=1
        break
    fi
    sleep 1
done

if [ "$READY" -eq 0 ]; then
    echo "❌ Zerro не поднялся за 30 секунд. Логи:"
    $CONTAINER_CMD logs --tail 50 "$CONTAINER"
    exit 1
fi
echo "✅ Zerro запущен!"

# --- 5. Открываем браузер (защита от второго окна) ---
if pgrep -f -- "--app=${URL}" > /dev/null; then
    echo "✅ Окно Zerro уже открыто"
else
    mkdir -p "$(dirname "$CHROME_PROFILE")"
    "$BROWSER" \
        --user-data-dir="$CHROME_PROFILE" \
        --disable-extensions \
        --disable-background-mode \
        --no-first-run \
        --app="$URL" > /dev/null 2>&1 &
    disown
fi

# --- 6. Ждём закрытия окна браузера ---
echo "📱 Закройте окно для остановки Zerro..."
while pgrep -f -- "--app=${URL}" > /dev/null; do
    sleep 2
done

# --- 7. Останавливаем контейнер ---
echo "🛑 Останавливаем контейнер..."
$CONTAINER_CMD stop "$CONTAINER" > /dev/null 2>&1 || true
echo "✅ Готово!"

# Блокировка снимется автоматически при выходе

