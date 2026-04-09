#!/bin/bash

# Проверяем запущен ли контейнер
if docker ps --format "table {{.Names}}" | grep -q "^zerro-app$"; then
    echo "✅ Zerro уже запущен"
    google-chrome --disable-extensions --app=http://localhost:3000 > /dev/null 2>&1 &
    disown
    exit 0
fi

# Проверяем, есть ли остановленный контейнер
if docker ps -a --format '{{.Names}}' | grep -q "^zerro-app$"; then
    CONTAINER_IMAGE=$(docker inspect --format='{{.Image}}' zerro-app 2>/dev/null)
    CURRENT_IMAGE=$(docker inspect --format='{{.Id}}' zerro:local 2>/dev/null)

    if [ "$CONTAINER_IMAGE" == "$CURRENT_IMAGE" ]; then
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
google-chrome --disable-extensions --app=http://localhost:3000 > /dev/null 2>&1 &

# Ждем закрытия Chrome
echo "📱 Закройте окно для остановки Zerro..."
while pgrep -f "chrome.*--app=http://localhost:3000" > /dev/null; do
    sleep 2
done

# Останавливаем контейнер
docker stop zerro-app > /dev/null
echo "✅ Готово!"